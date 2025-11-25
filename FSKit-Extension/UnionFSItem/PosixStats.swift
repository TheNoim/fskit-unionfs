//
//  PosixStats.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 25.11.25.
//

import Foundation

struct PosixStat {
    let mode: UInt32
    let flags: UInt32
    let birthTime: timespec
    let changeTime: timespec
    let modifyTime: timespec
    let accessTime: timespec
    let linkCount: UInt32
}
