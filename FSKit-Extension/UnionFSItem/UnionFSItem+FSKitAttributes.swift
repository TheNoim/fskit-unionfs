//
//  UnionFSItem+FSKitAttributes.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 23.11.25.
//

import FSKit

extension UnionFSItem {
    var attributes: FSItem.Attributes {
        let attributes = FSItem.Attributes()
        attributes.type = type
        attributes.fileID = fileId
        attributes.inhibitKernelOffloadedIO = false
        attributes.supportsLimitedXAttrs = false
                        
        if let selfAsDir = self as? UnionFSDirectory {
            if selfAsDir.isRoot {
                attributes.parentID = .parentOfRoot
                attributes.mode = UInt32(S_IFDIR) | 0o755
            } else {
                if let parentFileId = selfAsDir.parent?.fileId {
                    attributes.parentID = parentFileId
                }
            }
            attributes.size = 1
            attributes.allocSize = 1
            attributes.linkCount = 2
            
            let nowTimespec = timespec(from: Date.now)
            
            attributes.birthTime = nowTimespec
            attributes.accessTime = nowTimespec
            attributes.modifyTime = nowTimespec
            attributes.changeTime = nowTimespec
        } else if let selfAsFile = self as? UnionFSFile {
            attributes.parentID = selfAsFile.directory.fileId
        }
                
        if let nativeAttributes = nativeAttributes {
            if let uid = nativeAttributes[.ownerAccountID] as? UInt32 {
                attributes.uid = uid
            }
            if let gid = nativeAttributes[.groupOwnerAccountID] as? UInt32 {
                attributes.gid = gid
            }
            if let size = nativeAttributes[.size] as? UInt64 {
                attributes.size = size
                attributes.allocSize = size
            }
            if let creationDate = nativeAttributes[.creationDate] as? Date {
                attributes.birthTime = timespec(from: creationDate)
                attributes.changeTime = timespec(from: creationDate)
            }
            if let modificationDate = nativeAttributes[.modificationDate] as? Date {
                attributes.modifyTime = timespec(from: modificationDate)
            }
        }
        
        attributes.addedTime = timespec(from: self.addedTime)
        
        if let posixStat = posixStat {
            attributes.mode = posixStat.mode
            attributes.flags = posixStat.flags
            attributes.birthTime = posixStat.birthTime
            attributes.accessTime = posixStat.accessTime
            attributes.modifyTime = posixStat.modifyTime
            attributes.changeTime = posixStat.changeTime
            attributes.linkCount = posixStat.linkCount
        }
        
        return attributes
    }
}
