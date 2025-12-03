//
//  FSAttributes.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 03.12.25.
//

import Foundation
import FSKit

final class FSAttributes {
    let accessTime: timespec
    let birthTime: timespec
    let blockSize: Int32
    let blocks: Int64
    let changeTime: timespec
    let dev: Int32
    let flags: UInt32
    let gen: UInt32
    let gid: UInt32
    let inode: UInt64
    let lspare: Int32
    let mode: UInt16
    let modifiedTime: timespec
    let linkCount: UInt16
    let qspare: (Int64, Int64)
    let rdev: Int32
    let size: Int64
    let uid: UInt32
    let addedTime: timespec = timespec(from: Date.now)
    let type: FileType
    
    init(accessTime: timespec, birthTime: timespec, blockSize: Int32, blocks: Int64, changeTime: timespec, dev: Int32, flags: UInt32, gen: UInt32, gid: UInt32, inode: UInt64, lspare: Int32, mode: UInt16, modifiedTime: timespec, linkCount: UInt16, qspare: (Int64, Int64), rdev: Int32, size: Int64, uid: UInt32, type: FileType) {
        self.accessTime = accessTime
        self.birthTime = birthTime
        self.blockSize = blockSize
        self.blocks = blocks
        self.changeTime = changeTime
        self.dev = dev
        self.flags = flags
        self.gen = gen
        self.gid = gid
        self.inode = inode
        self.lspare = lspare
        self.mode = mode
        self.modifiedTime = modifiedTime
        self.linkCount = linkCount
        self.qspare = qspare
        self.rdev = rdev
        self.size = size
        self.uid = uid
        self.type = type
    }
    
    convenience init(darwinStat: stat, type: FileType) {
        self.init(accessTime: darwinStat.st_atimespec, birthTime: darwinStat.st_birthtimespec, blockSize: darwinStat.st_blksize, blocks: darwinStat.st_blocks, changeTime: darwinStat.st_ctimespec, dev: darwinStat.st_dev, flags: darwinStat.st_flags, gen: darwinStat.st_gen, gid: darwinStat.st_gid, inode: darwinStat.st_ino, lspare: darwinStat.st_lspare, mode: darwinStat.st_mode, modifiedTime: darwinStat.st_mtimespec, linkCount: darwinStat.st_nlink, qspare: darwinStat.st_qspare, rdev: darwinStat.st_rdev, size: Int64(darwinStat.st_size), uid: darwinStat.st_uid, type: type)
    }
    
    /// Fill out a attribute get request from FSKit.
    /// It will not fill the following attributes
    /// - `backupTime`: I don't know how to get this
    /// - `fileID`: Fill out yourself
    /// - `parentID`: Fill out yourself
    @discardableResult
    func fulfillAttribute(request: FSItem.GetAttributesRequest, attributes: inout FSItem.Attributes) -> FSItem.Attributes {
        if request.isAttributeWanted(.accessTime) {
            attributes.accessTime = self.accessTime
        }
        if request.isAttributeWanted(.addedTime) {
            attributes.addedTime = self.addedTime
        }
        if request.isAttributeWanted(.allocSize) {
            attributes.allocSize = UInt64(self.size)
        }
        if request.isAttributeWanted(.backupTime) {
            // TODO: find out what to do with that
        }
        if request.isAttributeWanted(.birthTime) {
            attributes.birthTime = self.birthTime
        }
        if request.isAttributeWanted(.changeTime) {
            attributes.changeTime = self.changeTime
        }
        if request.isAttributeWanted(.fileID) {
            // TODO: do outside of this class
        }
        if request.isAttributeWanted(.flags) {
            attributes.flags = self.flags
        }
        if request.isAttributeWanted(.gid) {
            attributes.gid = self.gid
        }
        if request.isAttributeWanted(.inhibitKernelOffloadedIO) {
            attributes.inhibitKernelOffloadedIO = false
        }
        if request.isAttributeWanted(.linkCount) {
            attributes.linkCount = UInt32(self.linkCount)
        }
        if request.isAttributeWanted(.mode) {
            attributes.mode = UInt32(self.mode)
        }
        if request.isAttributeWanted(.modifyTime) {
            attributes.modifyTime = self.modifiedTime
        }
        if request.isAttributeWanted(.parentID) {
            // TODO: do outside of this class
        }
        if request.isAttributeWanted(.size) {
            attributes.size = UInt64(self.size)
        }
        if request.isAttributeWanted(.supportsLimitedXAttrs) {
            attributes.supportsLimitedXAttrs = false // TODO: find out what to do about this
        }
        if request.isAttributeWanted(.type) {
            switch self.type {
            case .regular:
                attributes.type = .file
            case .directory:
                attributes.type = .directory
            case .symlink:
                attributes.type = .symlink
            case .other:
                attributes.type = .unknown // TODO: fix this
            case .unknown:
                attributes.type = .unknown
            }
        }
        if request.isAttributeWanted(.uid) {
            attributes.uid = self.uid
        }
                
        return attributes
    }
}

//let st = stat()
//st.st_atimespec
//st.st_birthtimespec
//st.st_blksize
//st.st_blocks
//st.st_ctimespec
//st.st_dev
//st.st_flags
//st.st_gen
//st.st_gid
//st.st_ino
//st.st_lspare
//st.st_mode
//st.st_mtimespec
//st.st_nlink
//st.st_qspare
//st.st_rdev
//st.st_size
//st.st_uid

