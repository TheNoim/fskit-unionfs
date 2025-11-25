//
//  FSKit_Extension.swift
//  FSKit-Extension
//
//  Created by Nils Bergmann on 22.11.25.
//

import ExtensionFoundation
import Foundation
import FSKit

@main
struct FSKit_Extension : UnaryFileSystemExtension {
    var fileSystem : FSUnaryFileSystem & FSUnaryFileSystemOperations {
        UnionFS()
    }
}
