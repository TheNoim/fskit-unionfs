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
            
                    UnionFSDirectory.logger.debug("Call readDirPlus for \(urlInBranch, privacy: .public)")
                    
                    if let entries = try? readDirPlus(at: urlInBranch) {
                        for entry in entries {
                            if case .directory = entry.type {
                                let dir = UnionFSDirectory(name: entry.name, availableOnBranches: [branch], parent: self, fsAttributes: FSAttributes(darwinStat: entry.info, type: entry.type))
                                branchItems.append(dir)
                            } else if case .regular = entry.type {
                                let file = UnionFSFile(directory: self, name: entry.name, branch: branch, fsAttributes: FSAttributes(darwinStat: entry.info, type: entry.type))
                                branchItems.append(file)
                            }
                        }
                    } else {
                        UnionFSDirectory.logger.error("Call readDirPlus for \(urlInBranch, privacy: .public) failed")
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
