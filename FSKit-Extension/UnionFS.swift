//
//  FSKit_ExtensionFileSystem.swift
//  FSKit-Extension
//
//  Created by Nils Bergmann on 22.11.25.
//

import Foundation
import FSKit

final class UnionFS : FSUnaryFileSystem & FSUnaryFileSystemOperations {
    private var logger = Logger(subsystem: Constants.extensionIdentifier, category: "FS")
        
    func probeResource(resource: FSResource, replyHandler: @escaping (FSProbeResult?, (any Error)?) -> Void) {
        logger.info("Probe resource")
        do {
            let options = try self.validateResource(resource: resource)
            
            logger.info("Probe resource success. The volume name is \(options.volumeName)")
            
            replyHandler(.usable(name: options.volumeName, containerID: FSContainerIdentifier(uuid: Constants.containerIdentifier)), nil)
        } catch {
            replyHandler(.notRecognized, error)
        }
    }
    
    func loadResource(resource: FSResource, options: FSTaskOptions, replyHandler: @escaping (FSVolume?, (any Error)?) -> Void) {
        logger.info("Load resource")
        
        do {
            let options = try self.validateResource(resource: resource)
            
            containerStatus = .ready
            
            replyHandler(UnionFSVolume(options: options), nil)
        } catch {
            replyHandler(nil, error)
        }
    }

    func unloadResource(resource: FSResource, options: FSTaskOptions) async throws {
        logger.info("Unload resouce")
    }
    
    func didFinishLoading() {
        logger.info("didFinishLoading")
    }
    
    /// Validate a FSResource if it is compatible with our unionfs.
    ///
    private func validateResource(resource: FSResource) throws(UnionFSError) -> UnionFSOption {
        if let urlResource = resource as? FSGenericURLResource {
            guard let schema = urlResource.url.scheme else {
                throw .unsupportedProtocol(provided: nil)
            }
            if schema != Constants.urlProtocolSchema {
                throw .unsupportedProtocol(provided: schema)
            }
            guard let volName = urlResource.url.host(percentEncoded: false) else {
                throw .missingVolumeName
            }
            
            let components = URLComponents(url: urlResource.url, resolvingAgainstBaseURL: false)
            
            var paths: [UnionBranch] = []
            
            var capacityMode = UnionFSCapacityMode.min
            
            if let queryItems = components?.queryItems {
                for (index, queryItem) in queryItems.enumerated() {
                    if queryItem.name == "br" {
                        if let value = queryItem.value {
                            var split = value.components(separatedBy: ";")
                            if let path = split.first {
                                let firstPathSplit = path.components(separatedBy: "=")
                                var path: String? = nil
                                var mode: UnionBranchMode = .RW
                                var prio = index
                                if firstPathSplit.count == 1 {
                                    // first split is not an option. I can interpret this as the path option
                                    path = split.remove(at: 0) // remove path option
                                }
                                for option in split {
                                    let optionSplit = option.components(separatedBy: "=")
                                    if optionSplit.count == 2 {
                                        let key = optionSplit.first! // count is >= 1, first can't be nil
                                        let value = optionSplit.last! // count is >= 1, last, can't be nil
                                        
                                        if key == "mode" {
                                            if value.lowercased() == "rw" {
                                                mode = .RW
                                            }
                                        } else if key == "prio" {
                                            if let prioAsInt = Int(value) {
                                                prio = prioAsInt
                                            }
                                        }
                                    }
                                }
                                if let path = path {
                                    paths.append(UnionBranch(path: path, prio: prio, mode: mode))
                                }
                            } // otherwise no branch is provided. Results in empty fs
                        }
                    } else if queryItem.name == "capacity" {
                        if let value = queryItem.value {
                            switch value {
                            case "combine":
                                capacityMode = .combine
                            case "max":
                                capacityMode = .max
                            case "min":
                                capacityMode = .min
                            default:
                                self.logger.error("Failed to parse capacity option \"\(value, privacy: .public)\". Use default.")
                                capacityMode = .min
                            }
                        } else {
                            self.logger.error("Failed to parse capacity option. Use default.")
                        }
                    }
                }
            }
            
            let caseFormatSet = Set(paths.map { $0.caseFormat })
            let mixedCaseFormats = caseFormatSet.count > 1
            
            if mixedCaseFormats {
                throw .mixedCaseFormats
            }
            
            return UnionFSOption(volumeName: volName, branches: paths, capacityMode: capacityMode, caseFormat: caseFormatSet.first ?? .insensitive)
        } else {
            throw .notGenericUrl
        }
    }
}
