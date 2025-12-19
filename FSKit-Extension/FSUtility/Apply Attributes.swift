//
//  Apply Attributes.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 15.12.25.
//

import Foundation
import FSKit

/// Applies a SetAttributesRequest to a file or directory path
func applyAttributes(at path: String, attributes: FSItem.SetAttributesRequest, prevStat: stat? = nil) throws {
    var st = stat()
    
    var r: Int32 = 0
    
    if prevStat != nil {
        st = prevStat!
    } else {
        r = stat(path, &st)
    }
    
    if r == 0 {
        if attributes.isValid(.uid) && attributes.isValid(.gid) {
            if st.st_uid != attributes.uid || st.st_gid != attributes.gid {
                r = chown(path, attributes.uid, attributes.gid)
                if r != 0 {
                    throw fs_errorForPOSIXError(errno)
                }
                attributes.consumedAttributes.insert(.uid)
                attributes.consumedAttributes.insert(.gid)
            }
        }
        if attributes.isValid(.flags) {
            if st.st_flags != attributes.flags {
                r = chflags(path, attributes.flags)
                if r != 0 {
                    throw fs_errorForPOSIXError(errno)
                }
                attributes.consumedAttributes.insert(.flags)
            }
        }
        if attributes.isValid(.mode) {
            if st.st_mode != attributes.mode {
                r = chmod(path, mode_t(attributes.mode))
                if r != 0 {
                    throw fs_errorForPOSIXError(errno)
                }
                attributes.consumedAttributes.insert(.mode)
            }
        }
        if attributes.isValid(.accessTime) && attributes.isValid(.modifyTime) {
            if st.st_atimespec != attributes.accessTime || st.st_mtimespec != attributes.modifyTime {
                var times = [
                    attributes.accessTime,
                    attributes.modifyTime
                ]
                r = utimensat(AT_FDCWD, path, &times, 0)
                if r != 0 {
                    throw fs_errorForPOSIXError(errno)
                }
                attributes.consumedAttributes.insert(.accessTime)
                attributes.consumedAttributes.insert(.modifyTime)
            }
        }
    } else {
        throw fs_errorForPOSIXError(errno)
    }
}

extension timespec: @retroactive Equatable {
    public static func == (lhs: timespec, rhs: timespec) -> Bool {
        return lhs.tv_nsec == rhs.tv_nsec && lhs.tv_sec == rhs.tv_sec
    }
}
