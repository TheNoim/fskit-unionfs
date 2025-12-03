//
//  UnionFSItem+FSKitAttributes.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 23.11.25.
//

import FSKit

extension UnionFSItem {
    func fulfillAttribute(request: FSItem.GetAttributesRequest) -> FSItem.Attributes {
        var attributes = FSItem.Attributes()
        
        if let fsAttributes = fsAttributes {
            fsAttributes.fulfillAttribute(request: request, attributes: &attributes)
        }
        
        if request.isAttributeWanted(.fileID) {
            attributes.fileID = self.fileId
        }
        
        if request.isAttributeWanted(.parentID) {
            if let dir = self as? UnionFSDirectory {
                if let parent = dir.parent {
                    attributes.parentID = parent.fileId
                } else if dir.fileId == .rootDirectory {
                    attributes.parentID = .parentOfRoot
                }
            }
            if let file = self as? UnionFSFile {
                attributes.parentID = file.directory.fileId
            }
        }
        
        return attributes
    }
}
