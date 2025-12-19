//
//  UnionFSVolume+PickBranch.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 15.12.25.
//

extension UnionFSVolume {
    func pickNextBranch() -> UnionBranch {
        self.options.branches.filter({ $0.mode == .RW }).sorted(by: { $0.volumeAvailableCapacity > $1.volumeTotalCapacity }).first!
    }
}
