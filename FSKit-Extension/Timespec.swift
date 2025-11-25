//
//  Timespec.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 25.11.25.
//

import Foundation

extension timespec {
    init(from date: Date) {
        let interval = date.timeIntervalSince1970
        let sec = time_t(interval)
        let nsec = Int((interval - Double(sec)) * 1_000_000_000)
        self.init(tv_sec: sec, tv_nsec: nsec)
    }
}
