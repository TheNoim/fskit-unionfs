//
//  UnionFSItem.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//

import FSKit

class UnionFSItem: FSItem {
    private static var id: UInt64 = FSItem.Identifier.rootDirectory.rawValue + 1
    static func getNextID() -> UInt64 {
        let current = id
        id += 1
        return current
    }
    
    let id = UUID()
    
    var fileId: FSItem.Identifier
    
    var name: FSFileName
    var nativeAttributes: [FileAttributeKey: Any]? = nil
    var posixStat: PosixStat? = nil
    var type: FSItem.ItemType
    
    let addedTime: Date = .now
    
    init(name: FSFileName, type: FSItem.ItemType, nativeAttributes: [FileAttributeKey : Any]? = nil) {
        self.name = name
        self.nativeAttributes = nativeAttributes
        self.type = type
        if let nativeAttributes = nativeAttributes {
            if let realFileId = nativeAttributes[.systemFileNumber] as? UInt64 {
                self.fileId = FSItem.Identifier(rawValue: realFileId)!
            } else {
                self.fileId = FSItem.Identifier(rawValue: UnionFSItem.getNextID())!
            }
        } else {
            self.fileId = FSItem.Identifier(rawValue: UnionFSItem.getNextID())!
        }
    }
}
