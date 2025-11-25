//
//  Helper.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 23.11.25.
//
import OSLog

class Helper: HelperProtocol {
    private let logger = Logger(subsystem: "UnionFSHelper", category: "Helper")
    
    static let shared = Helper()
    
    func resourceValues(for url: URL, completion: @escaping (TransferableURLResourceValues?, (any Error)?) -> Void) {
        do {
            let resources = try url.resourceValues(forKeys: [
                .volumeUUIDStringKey,
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey,
                .volumeSupportsImmutableFilesKey,
                .volumeSupportsCasePreservedNamesKey,
                .volumeSupportsCaseSensitiveNamesKey
            ])
            
            completion(TransferableURLResourceValues(from: resources), nil)
        } catch {
            completion(nil, error)
        }
    }
    
    func attributesOfItem(at path: String, completion: @escaping (TransferableFileAttributes?, (any Error)?) -> Void) {
        DispatchQueue.global().async {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                let transferable = TransferableFileAttributes(raw: attributes)
                completion(transferable, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, completion: @escaping ([String]?, (any Error)?) -> Void) {
        DispatchQueue.global().async {
            do {
                let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys).map({ $0.absoluteString })
                completion(urls, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
}
