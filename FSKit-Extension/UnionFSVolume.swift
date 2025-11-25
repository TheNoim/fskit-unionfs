//
//  UnionFSVolume.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//
import FSKit
import os

class UnionFSVolume: FSVolume {
    internal var logger = Logger(subsystem: Constants.extensionIdentifier, category: "Volume")
    
    let uuid = UUID()
    let options: UnionFSOption
    
    var root: UnionFSDirectory? = nil
        
    init(options: UnionFSOption) {
        self.options = options
        
        super.init(volumeID: FSVolume.Identifier(uuid: self.uuid), volumeName: FSFileName(string: options.volumeName))
        
        self.logger.info("Init volume with id \(self.uuid) and name \(self.options.volumeName)")
    }
}
