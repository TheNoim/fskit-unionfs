//
//  FSKit_ExtensionFileSystemOptions.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//
import Foundation
import FSKit

struct UnionFSOption {
    let volumeName: String
    let branches: [UnionBranch]
    let capacityMode: UnionFSCapacityMode
    let caseFormat: FSVolume.CaseFormat
}
