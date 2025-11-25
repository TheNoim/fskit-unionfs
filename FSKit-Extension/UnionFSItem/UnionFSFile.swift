//
//  UnionFSFile.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//

import FSKit

final class UnionFSFile: UnionFSItem {
    var directory: UnionFSDirectory
    var onBranch: UnionBranch
    
    init(directory: UnionFSDirectory, name: FSFileName, branch: UnionBranch) {
        self.directory = directory
        self.onBranch = branch
        super.init(name: name, type: .file)
        self.name = name
    }
}
