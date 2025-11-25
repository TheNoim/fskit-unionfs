//
//  UnionBranch+PathInBranch.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//
import Foundation
import FSKit

extension UnionBranch {
    func urlInBranchFor(dir: UnionFSDirectory) -> URL? {
        var url = URL(string: "file:///")
        
        url?.append(path: self.path)
        url?.append(path: dir.rootRelativePath)
        
        return url
    }
    
    func urlInBranchFor(file: UnionFSFile) -> URL? {
        let directoryUrl = self.urlInBranchFor(dir: file.directory)
        
        let fileUrl = directoryUrl?.appending(path: file.name.string!)
        
        return fileUrl
    }
}
