//
//  HelperProtocol.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 23.11.25.
//

import Foundation

@objc(HelperProtocol)
public protocol HelperProtocol {
    func resourceValues(for url: URL, completion: @escaping (TransferableURLResourceValues?, Error?) -> Void) -> Void
    
    func attributesOfItem(at path: String, completion: @escaping (TransferableFileAttributes?, Error?) -> Void) -> Void
    
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, completion: @escaping ([String]?, Error?) -> Void) -> Void
}
