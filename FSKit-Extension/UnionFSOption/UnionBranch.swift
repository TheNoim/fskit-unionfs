//
//  UnionBranch.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//
import Foundation

struct UnionBranch: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let prio: Int
    let mode: UnionBranchMode
    
    internal let fallbackUUID = UUID()
    
    var url: URL {
        return URL(filePath: self.path)
    }
    
    init(path: String, prio: Int, mode: UnionBranchMode) {
        if path.hasSuffix("/") {
            var pathWithoutSlash = path
            pathWithoutSlash.removeLast()
            self.path = pathWithoutSlash
        } else {
            self.path = path
        }
        self.prio = prio
        self.mode = mode
    }
}
