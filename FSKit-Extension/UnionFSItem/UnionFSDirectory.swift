//
//  UnionFSDirectory.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//
import FSKit
import Semaphore

class UnionFSDirectory: UnionFSItem {
    static let logger = Logger(subsystem: Constants.extensionIdentifier, category: "UnionFSDirectory")
    
    var parent: UnionFSDirectory? = nil
    
    var items: [UnionFSItem]? = nil
    
    var availableOnBranches: [UnionBranch]
    
    internal let itemSemaphore = AsyncSemaphore(value: 1)
        
    init(parent: UnionFSDirectory? = nil, items: [UnionFSItem]? = nil, availableOnBranches: [UnionBranch], name: FSFileName) {
        self.parent = parent
        self.items = items
        self.availableOnBranches = availableOnBranches
        super.init(name: name, type: .directory)
        if self.isRoot {
            self.fileId = .rootDirectory
        }
    }
    
    convenience init(name: String, availableOnBranches: [UnionBranch]) {
        let fsName = FSFileName(string: name)
        self.init(availableOnBranches: availableOnBranches, name: fsName)
    }
    
    convenience init(name: String, availableOnBranches: [UnionBranch], parent: UnionFSDirectory, fsAttributes: FSAttributes) {
        let fsName = FSFileName(string: name)
        self.init(name: name, availableOnBranches: availableOnBranches)
        self.parent = parent
        self.fsAttributes = fsAttributes
    }
    
    var rootRelativePath: String {
        guard let parent = parent else {
            return "" // is root
        }
        
        return "\(parent.rootRelativePath)/\(self.name.string!)"
    }
    
    lazy var isRoot: Bool = {
        parent == nil
    }()
}
