//
//  UnionFSVolume+Operations.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//

import FSKit
import Foundation
import RegexBuilder

let doubleRegex = Regex {
    Anchor.startOfSubject
    Character(".")
    Character("_")
}

extension UnionFSVolume: FSVolume.Operations {
    func activate(options: FSTaskOptions) async throws -> FSItem {
        let rootDirectory = UnionFSDirectory(name: self.options.volumeName, availableOnBranches: self.options.branches)
        
        let now = timespec(from: Date.now)
        
        let attributes = FSAttributes(accessTime: now, birthTime: now, blockSize: 0, blocks: 0, changeTime: now, dev: 0, flags: 0, gen: 0, gid: getegid(), inode: 0, lspare: 0, mode: 0o755, modifiedTime: now, linkCount: 2, qspare: (0, 0), rdev: 0, size: 0, uid: geteuid(), type: .directory)
        
        rootDirectory.fsAttributes = attributes
        
        self.root = rootDirectory
        
        self.logger.info("Volume \(self.options.volumeName, privacy: .public) (\(self.uuid.uuidString, privacy: .public)) activated. Options: \(options.taskOptions, privacy: .public)");
        
        return rootDirectory
    }
    
    func deactivate(options: FSDeactivateOptions = []) async throws {
        self.root = nil
        self.logger.info("Volume \(self.options.volumeName) (\(self.uuid.uuidString)) deactivated")
    }
    
    func mount(options: FSTaskOptions) async throws {
        self.logger.info("Volume \(self.options.volumeName, privacy: .public) (\(self.uuid.uuidString, privacy: .public)) mounted")
    }
    
    func unmount() async {
        self.logger.info("Volume \(self.options.volumeName, privacy: .public) (\(self.uuid.uuidString, privacy: .public)) unmounted")
    }
    
    func createItem(named name: FSFileName, type: FSItem.ItemType, inDirectory directory: FSItem, attributes newAttributes: FSItem.SetAttributesRequest) async throws -> (FSItem, FSFileName) {
        self.logger.debug("createItem")
        
        throw fs_errorForPOSIXError(POSIXError.ENOTSUP.rawValue)
        
//        guard let dir = directory as? UnionFSDirectory else {
//            self.logger.error("createItem failed, because directory is not an directory")
//            throw fs_errorForPOSIXError(POSIXError.ENOTDIR.rawValue)
//        }
//        
//        let nextBranch = self.pickNextBranch()
//        
//        if case .file = type {
//            
//        } else if case .directory = type {
//            guard let pathToCreate = nextBranch.urlInBranchFor(dir: dir)?.appending(path: name.string!, directoryHint: .isDirectory).absoluteString else {
//                throw fs_errorForPOSIXError(POSIXError.EBADRPC.rawValue) // TODO: use diff err
//            }
//            try mkdirPlus(at: pathToCreate, recursive: true, attributes: newAttributes)
//        } else {
//            throw fs_errorForPOSIXError(POSIXError.ENODEV.rawValue)
//        }
    }
    
    func lookupItem(named name: FSFileName, inDirectory directory: FSItem) async throws -> (FSItem, FSFileName) {
        if (name.string?.starts(with: doubleRegex) ?? false) {
            throw fs_errorForPOSIXError(POSIXError.ENOENT.rawValue)
        }
        self.logger.info("lookupItem with name \(name.string ?? "nil", privacy: .public)")
        guard let unionDir = directory as? UnionFSDirectory else {
            self.logger.info("Can not cast as dir")
            throw fs_errorForPOSIXError(POSIXError.ENOENT.rawValue)
        }
        
        let items = try await unionDir.getItems()
        
        guard let item = items.first(where: { $0.name.string == name.string }) else {
            self.logger.debug("Item not found in items. Item count: \(items.count)")
            throw fs_errorForPOSIXError(POSIXError.ENOENT.rawValue)
        }
        self.logger.debug("Lookup successfully. Item found")
        return (item, item.name)
    }
    
    func removeItem(_ item: FSItem, named name: FSFileName, fromDirectory directory: FSItem) async throws {
        self.logger.debug("removeItem")
        throw fs_errorForPOSIXError(POSIXError.EIO.rawValue)
    }
    
    func renameItem(_ item: FSItem, inDirectory sourceDirectory: FSItem, named sourceName: FSFileName, to destinationName: FSFileName, inDirectory destinationDirectory: FSItem, overItem: FSItem?, replyHandler reply: @escaping (FSFileName?, (any Error)?) -> Void) {
        self.logger.debug("renameItem")
        reply(nil, fs_errorForPOSIXError(POSIXError.EIO.rawValue))
    }
    
    func reclaimItem(_ item: FSItem) async throws {
        self.logger.debug("reclaimItem")
    }
    
    func createLink(to item: FSItem, named name: FSFileName, inDirectory directory: FSItem) async throws -> FSFileName {
        self.logger.debug("createLink")
        throw fs_errorForPOSIXError(POSIXError.EIO.rawValue)
    }
    
    func createSymbolicLink(named name: FSFileName, inDirectory directory: FSItem, attributes newAttributes: FSItem.SetAttributesRequest, linkContents contents: FSFileName) async throws -> (FSItem, FSFileName) {
        self.logger.debug("createSymbolicLink")
        throw fs_errorForPOSIXError(POSIXError.EIO.rawValue)
    }
    
    func readSymbolicLink(_ item: FSItem) async throws -> FSFileName {
        self.logger.debug("readSymbolicLink")
        throw fs_errorForPOSIXError(POSIXError.ENOENT.rawValue)
    }
    
    func attributes(_ desiredAttributes: FSItem.GetAttributesRequest, of item: FSItem) async throws -> FSItem.Attributes {
        guard let unionItem = item as? UnionFSItem else {
            self.logger.debug("attributes req failed")
            throw fs_errorForPOSIXError(POSIXError.ENOENT.rawValue)
        }
        
        return unionItem.fulfillAttribute(request: desiredAttributes)
    }
    
    func setAttributes(_ newAttributes: FSItem.SetAttributesRequest, on item: FSItem) async throws -> FSItem.Attributes {
        self.logger.debug("setAttributes")
        throw fs_errorForPOSIXError(POSIXError.EIO.rawValue)
    }
    
    func enumerateDirectory(_ directory: FSItem, startingAt cookie: FSDirectoryCookie, verifier: FSDirectoryVerifier, attributes: FSItem.GetAttributesRequest?, packer: FSDirectoryEntryPacker, replyHandler reply: @escaping (FSDirectoryVerifier, (any Error)?) -> Void) {
        
        self.logger.debug("enumerateDirectory")

        guard let dir = directory as? UnionFSDirectory else {
            reply(verifier, fs_errorForPOSIXError(POSIXError.ENOENT.rawValue));
            return
        }
        
        self.logger.debug("Directory to enumerate: \(dir.name.string ?? "nil", privacy: .public)")
        
        Task {
            do {
                let items = try await dir.getItems()

                if attributes == nil && !dir.isRoot {
                    self.logger.debug("Pack . dir")
                    packer.packEntry(name: FSFileName(string: "."), itemType: .directory, itemID: dir.fileId, nextCookie: cookie, attributes: attributes != nil ? dir.fulfillAttribute(request: attributes!) : nil)
                    if let parent = dir.parent {
                        self.logger.debug("Pack .. dir")
                        packer.packEntry(name: FSFileName(string: ".."), itemType: .directory, itemID: parent.fileId, nextCookie: cookie, attributes: attributes != nil ? parent.fulfillAttribute(request: attributes!) : nil)
                    }
                }

                for item in items {
                    self.logger.debug("Pack item with name \(item.name.string ?? "nil", privacy: .public)")
                    packer.packEntry(name: item.name, itemType: item.type, itemID: item.fileId, nextCookie: cookie, attributes: attributes != nil ? item.fulfillAttribute(request: attributes!) : nil)
                }
                
                self.logger.debug("End of enumerateDirectory")
                
                reply(verifier, nil)
            } catch {
                self.logger.error("Failed to get items. Error: \(error, privacy: .public)")
                reply(verifier, error)
            }
            
        }
    }
    
    func synchronize(flags: FSSyncFlags) async throws {
        self.logger.debug("Called synchronize")
    }
    
    var supportedVolumeCapabilities: FSVolume.SupportedCapabilities {
        self.logger.debug("Query supportedVolumeCapabilities")
        
        let capabilities = FSVolume.SupportedCapabilities()
        
        capabilities.supportsHiddenFiles = true
        capabilities.doesNotSupportRootTimes = true
        capabilities.caseFormat = self.options.caseFormat
        capabilities.doesNotSupportVolumeSizes = true
        
        let immutableSet = self.options.branches.map { $0.volumeSupportsImmutableFiles }
        
        if immutableSet.count == 1 {
            capabilities.doesNotSupportImmutableFiles = !immutableSet.first!
        } else {
            capabilities.doesNotSupportImmutableFiles = true
        }
        
        return capabilities
    }
    
    var volumeStatistics: FSStatFSResult {
        self.logger.debug("Query volumeStatistics")
        
        let result = FSStatFSResult(fileSystemTypeName: Constants.shortName)
        
        result.blockSize = 1024000
        result.ioSize = 1024000
        result.totalBlocks = 1024000
        result.availableBlocks = 1024000
        result.freeBlocks = 1024000
        result.totalFiles = 1024000
        result.freeFiles = 1024000
        
        for branch in self.options.branches {
            let volumeTotalCapacity = UInt64(branch.volumeTotalCapacity)
            let volumeAvailableCapacity = UInt64(branch.volumeAvailableCapacity)
            let usedCapacity = volumeTotalCapacity - volumeAvailableCapacity
            switch self.options.capacityMode {
            case .combine:
                result.usedBytes = result.usedBytes + usedCapacity
                result.availableBytes = result.availableBytes + volumeAvailableCapacity
                result.totalBytes = result.totalBytes + volumeTotalCapacity
            case .max:
                if usedCapacity > result.usedBytes {
                    result.usedBytes = usedCapacity
                }
                if volumeAvailableCapacity > result.availableBytes {
                    result.availableBytes = volumeAvailableCapacity
                }
                if volumeTotalCapacity > result.totalBytes {
                    result.totalBytes = volumeTotalCapacity
                }
            case .min:
                if usedCapacity < result.usedBytes {
                    result.usedBytes = usedCapacity
                }
                if volumeAvailableCapacity < result.availableBytes {
                    result.availableBytes = volumeAvailableCapacity
                }
                if volumeTotalCapacity < result.totalBytes {
                    result.totalBytes = volumeTotalCapacity
                }
            }
        }
        
        return result
    }
}
