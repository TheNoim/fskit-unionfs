//
//  Untitled.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//

enum UnionFSError: Error {
    case notGenericUrl
    case missingVolumeName
    case mixedCaseFormats
    case unsupportedProtocol(provided: String?)
    
    public var description: String {
        switch self {
        case .notGenericUrl:
            return "FSResource is not an FSGenericURLResource"
        case .missingVolumeName:
            return ""
        case .unsupportedProtocol(let provided):
            return "FSGenericURLResource has the wrong protocol. You need to use \(Constants.urlProtocolSchema)://, but you used \(provided ?? "MISSING")://"
        case .mixedCaseFormats:
            return "You can not mixe case sensitive branches with case insensitive branches"
        }
    }
}
