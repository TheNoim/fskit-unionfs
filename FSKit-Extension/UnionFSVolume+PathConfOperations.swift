//
//  UnionFSVolume+PathConfOperations.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//
import FSKit
import Foundation

extension UnionFSVolume: FSVolume.PathConfOperations {
    var maximumLinkCount: Int {
        0
    }
    
    var maximumNameLength: Int {
        var currentMax = 255
        for branch in self.options.branches {
            if let max = self.maxNameLength(at: branch.url) {
                if max < currentMax {
                    currentMax = max
                }
            }
        }
        return currentMax
    }
    
    var restrictsOwnershipChanges: Bool {
        false
    }
    
    var truncatesLongNames: Bool {
        false
    }
    
    
    var maximumFileSize: UInt64 {
        var currentMaxSize = -1
        
        for branch in self.options.branches {
            if let resourceValues = try? branch.url.resourceValues(forKeys: [.volumeMaximumFileSizeKey]) {
                if let maxValue = resourceValues.volumeMaximumFileSize {
                    if currentMaxSize == -1 {
                        currentMaxSize = maxValue
                    } else if currentMaxSize > maxValue {
                        currentMaxSize = maxValue
                    }
                }
            }
        }
        
        if currentMaxSize == -1 {
            return UInt64.max
        }
        
        return UInt64(currentMaxSize)
    }
    
    var maximumXattrSize: Int {
        -1
    }
    
    private func maxNameLength(at url: URL) -> Int? {
        return url.withUnsafeFileSystemRepresentation { fsRep -> Int? in
            guard let fsRep = fsRep else { return nil }
            errno = 0
            let v = pathconf(fsRep, _PC_NAME_MAX)
            if v == -1 {
                return (errno == 0) ? nil : nil  // handle error / “no limit”
            }
            return Int(v)
        }
    }
}
