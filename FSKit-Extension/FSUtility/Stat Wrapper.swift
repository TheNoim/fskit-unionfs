//
//  Posix Stat.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 15.12.25.
//

import Foundation
import FSKit

/// Simple wrapper for posix stat
func posixStat(from path: String) throws -> stat {
    var st = stat()
    let r = stat(path, &st)
    if r != 0 {
        throw fs_errorForPOSIXError(errno)
    }
    return st
}
