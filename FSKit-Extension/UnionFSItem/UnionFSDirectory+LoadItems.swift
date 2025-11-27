//
//  UnionFSDirectory+LoadItems.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//
import Foundation
import Semaphore
import FSKit
import System

extension UnionFSDirectory {
    func getItems() async throws -> [UnionFSItem] {
        await self.itemSemaphore.wait()
        defer { self.itemSemaphore.signal() }
        
        if let items = self.items {
            return items
        }

        let fetchedItems = try await withThrowingTaskGroup(of: [UnionFSItem].self) { branchGroup in
            var allItems: [UnionFSItem] = []
            
            for branch in self.availableOnBranches {
                branchGroup.addTask {
                    var branchItems: [UnionFSItem] = []
                    
                    guard let urlInBranch = branch.urlInBranchFor(dir: self) else {
                        throw UnionFSItemError.failedToCreateDirectoryPath
                    }
                    
                    UnionFSDirectory.logger.debug("Call contentsOfDirectory for \(urlInBranch, privacy: .public)")
                    
                    let urls = try FileManager.default.contentsOfDirectory(at: urlInBranch, includingPropertiesForKeys: nil)
                    
                    let urlAttributes = try await withThrowingTaskGroup(of: (URL, [FileAttributeKey: Any], PosixStat).self) { attributeGroup in
                        for url in urls {
                            attributeGroup.addTask {
                                UnionFSDirectory.logger.debug("Call attributesOfItem for \(url.path(percentEncoded: false), privacy: .public)")
                                let path = url.path(percentEncoded: false)
                                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                                var st = stat()
                                stat(path, &st)
                                let posixStat = PosixStat(mode: UInt32(st.st_mode), flags: UInt32(st.st_flags), birthTime: st.st_birthtimespec, changeTime: st.st_ctimespec, modifyTime: st.st_mtimespec, accessTime: st.st_atimespec, linkCount: UInt32(st.st_nlink))
                                return (url, attributes, posixStat)
                            }
                        }
                        
                        var attributes: [(URL, [FileAttributeKey: Any], PosixStat)] = []
                        
                        for try await attr in attributeGroup {
                            attributes.append(attr)
                        }
                        
                        return attributes
                    }
                    
                    for (url, attr, posixStat) in urlAttributes {
                        if let type = attr[.type] as? FileAttributeType {
                            if type == .typeRegular {
                                let file = UnionFSFile(directory: self, name: FSFileName(string: url.lastPathComponent), branch: branch)
                                file.nativeAttributes = attr
                                file.posixStat = posixStat
                                branchItems.append(file)
                            } else if type == .typeDirectory {
                                let dir = UnionFSDirectory(name: url.lastPathComponent, availableOnBranches: [branch])
                                dir.parent = self
                                dir.nativeAttributes = attr
                                dir.posixStat = posixStat
                                branchItems.append(dir)
                            }
                        }
                    }
                    
                    return branchItems
                }
            }
            
            for try await branchItems in branchGroup {
                allItems.append(contentsOf: branchItems)
            }
            
            return allItems
        }
        
        let groupdByName = Dictionary(grouping: fetchedItems, by: { $0.name.hashValue })
        
        var finalItems: [UnionFSItem] = []
        
        for (_, sameName) in groupdByName {
            /// Sort explained:
            /// Priority number is sorted ascending. Lower value has higher priority.
            /// A file has priority over a directory
            
            let sortedByPriority = sameName.sorted(by: { a, b in
                if let aAsDir = a as? UnionFSDirectory {
                    if let bAsDir = b as? UnionFSDirectory {
                        return aAsDir.availableOnBranches.first!.prio < bAsDir.availableOnBranches.first!.prio
                    } else {
                        return false
                    }
                } else if let aAsFile = a as? UnionFSFile {
                    if let bAsFile = b as? UnionFSFile {
                        return aAsFile.onBranch.prio < bAsFile.onBranch.prio
                    } else {
                        return true
                    }
                }
                return false
            })
            
            if let objectWithHigherPrio = sortedByPriority.first {
                if let asDir = objectWithHigherPrio as? UnionFSDirectory {
                    let allBranches = sameName.compactMap({ $0 as? UnionFSDirectory }).compactMap({ $0.availableOnBranches.first })
                    asDir.availableOnBranches = Array(Set(allBranches))
                    finalItems.append(asDir)
                } else {
                    finalItems.append(objectWithHigherPrio)
                }
            }
        }
        
        self.items = finalItems
        
        return finalItems
    }
}
