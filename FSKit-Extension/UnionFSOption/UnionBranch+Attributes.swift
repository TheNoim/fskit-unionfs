//
//  UnionBranch+Attributes.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//

import Foundation
import FSKit

extension UnionBranch {
    var volumeIdentifier: String {
        if let resources = try? self.url.resourceValues(forKeys: [.volumeUUIDStringKey, .volumeNameKey]) {
            return resources.volumeUUIDString ?? resources.volumeName ?? self.fallbackUUID.uuidString
        }
        return self.fallbackUUID.uuidString
    }
    
    var volumeTotalCapacity: Int {
        if let resources = try? self.url.resourceValues(forKeys: [.volumeTotalCapacityKey]) {
            return resources.volumeTotalCapacity ?? 0
        }
        return 0
    }
    
    var volumeAvailableCapacity: Int {
        if let resources = try? self.url.resourceValues(forKeys: [.volumeAvailableCapacityKey]) {
            return resources.volumeAvailableCapacity ?? 0
        }
        return 0
    }
    
    var volumeSupportsImmutableFiles: Bool {
        if let resources = try? self.url.resourceValues(forKeys: [.volumeSupportsImmutableFilesKey]) {
            return resources.volumeSupportsImmutableFiles ?? false
        }
        return false
    }
    
    var caseFormat: FSVolume.CaseFormat {
        if let resources = try? self.url.resourceValues(forKeys: [.volumeSupportsCaseSensitiveNamesKey, .volumeSupportsCasePreservedNamesKey]) {
            if let volumeSupportsCaseSensitiveNames = resources.volumeSupportsCaseSensitiveNames {
                if volumeSupportsCaseSensitiveNames {
                    return .sensitive
                } else {
                    if let volumeSupportsCasePreservedNames = resources.volumeSupportsCasePreservedNames {
                        if volumeSupportsCasePreservedNames {
                            return .insensitiveCasePreserving
                        }
                    }
                }
            } else {
                if let volumeSupportsCasePreservedNames = resources.volumeSupportsCasePreservedNames {
                    if volumeSupportsCasePreservedNames {
                        return .insensitiveCasePreserving
                    }
                }
            }
        }
        return .insensitive
    }
}
