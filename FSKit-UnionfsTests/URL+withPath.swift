//
//  URL+withPath.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 29.11.25.
//

import Foundation

extension URL {
    /// Appends a path to the URL and returns path as string without percentEncoded enabled.
    func withPath(_ path: String) -> String {
        self.appending(path: path).path(percentEncoded: false)
    }
    
    /// Appends a path to the URL and returns path as string without percentEncoded enabled.
    func withPath(_ path: String, directoryHint: DirectoryHint) -> String {
        self.appending(path: path, directoryHint: directoryHint).path(percentEncoded: false)
    }
}
