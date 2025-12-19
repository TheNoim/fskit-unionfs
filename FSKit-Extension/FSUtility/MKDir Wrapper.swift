//
//  mkdirplus.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 15.12.25.
//

import Foundation
import FSKit
import System

/// mkdir wrapper
func mkdirPlus(at path: String, recursive: Bool = false, attributes: FSItem.SetAttributesRequest) throws {
    if !path.starts(with: "/") {
        throw MkdirPlusError.invalidPath
    }
    
    if !recursive {
        let r = mkdir(path, mode_t(attributes.mode))
        if r != 0 {
            throw fs_errorForPOSIXError(errno)
        }
        try applyAttributes(at: path, attributes: attributes)
        return
    }
    
    var pathsToCreate: [String] = []
    
    var currentPath = FilePath(path).removingLastComponent().string;
    
    while true {
        do {
            let _ = try posixStat(from: currentPath)
            break
        } catch {
            pathsToCreate.append(currentPath)
        }
        currentPath = FilePath(currentPath).removingLastComponent().string
        if currentPath == "/" {
            break
        }
        if currentPath.isEmpty {
            throw MkdirPlusError.recursiveCallEndedWithEmptyPath
        }
    }
    
    pathsToCreate.reverse()
    
    for pathToCreate in pathsToCreate {
        let r = mkdir(pathToCreate, mode_t(attributes.mode))
        if r != 0 {
            throw fs_errorForPOSIXError(errno)
        }
        try applyAttributes(at: pathToCreate, attributes: attributes)
    }
    
    let r = mkdir(path, mode_t(attributes.mode))
    if r != 0 {
        throw fs_errorForPOSIXError(errno)
    }
    try applyAttributes(at: path, attributes: attributes)
}

enum MkdirPlusError: Error {
    case invalidPath
    case recursiveCallEndedWithEmptyPath
    
    var description: String {
        switch self {
        case .invalidPath:
            return "The path has to be an absolute path starting with \"/\""
        case .recursiveCallEndedWithEmptyPath:
            return "While traveling up the path to create the directories, the path resulted in an empty string"
        }
    }
}
