//
//  UnionFSItem+Error.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//

enum UnionFSItemError: Error {
    case failedToCreateDirectoryPath
    
    public var description: String {
        switch self {
        case .failedToCreateDirectoryPath:
            return "urlInBranchFor failed to create a valid url"
        }
    }
}
