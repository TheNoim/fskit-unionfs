//
//  readdir.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 03.12.25.
//

import Foundation
import Darwin   // Glibc on Linux

enum FileType {
    case regular, directory, symlink, other, unknown
}

struct DirEntryPlus {
    let name: String
    let type: FileType
    let info: stat
}

func readDirPlus(at path: URL) throws -> [DirEntryPlus] {
    try path.withUnsafeFileSystemRepresentation { cPath in
        guard let dir = opendir(cPath) else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
        defer { closedir(dir) }

        let dfd = dirfd(dir)
        var result: [DirEntryPlus] = []

        while true {
            errno = 0
            guard let entry = readdir(dir) else {
                if errno != 0 { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
                break
            }

            // Build name using d_namlen (Darwin provides this field)
            let len = Int(entry.pointee.d_namlen)
            let name: String = withUnsafePointer(to: entry.pointee.d_name) { basePtr in
                basePtr.withMemoryRebound(to: CChar.self, capacity: len + 1) { ccharPtr in
                    // Create String from exact byte count (may skip the trailing NUL)
                    let u8ptr = UnsafeRawPointer(ccharPtr).assumingMemoryBound(to: UInt8.self)
                    return String(decoding: UnsafeBufferPointer(start: u8ptr, count: len), as: UTF8.self)
                }
            }
            if name == "." || name == ".." { continue }

            // stat via fstatat relative to dirfd (avoid following symlinks)
            var st = stat()
            let r = withUnsafePointer(to: entry.pointee.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: len + 1) {
                    fstatat(dfd, $0, &st, AT_SYMLINK_NOFOLLOW)
                }
            }
            if r != 0 { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }

            // file type: prefer d_type, fall back to st_mode
            let type: FileType = {
                let dt = entry.pointee.d_type
                switch dt {
                case UInt8(DT_REG):  return .regular
                case UInt8(DT_DIR):  return .directory
                case UInt8(DT_LNK):  return .symlink
                case UInt8(DT_UNKNOWN):
                    let m = st.st_mode & S_IFMT
                    if m == S_IFREG { return .regular }
                    if m == S_IFDIR { return .directory }
                    if m == S_IFLNK { return .symlink }
                    return .other
                default:
                    return .other
                }
            }()

            result.append(DirEntryPlus(name: name, type: type, info: st))
        }

        return result
    }
}
