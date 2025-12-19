//
//  Mkdir Test.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 16.12.25.
//

import Testing
import Foundation
import FSKit

@Suite("Mkdir Test")
class MkdirTest {
    static let logger = Logger()
    
    static func newTemporaryRoot() -> URL {
        let temporaryDir = FileManager.default.temporaryDirectory
        let name = UUID().uuidString
        let root = temporaryDir.appending(path: name, directoryHint: .isDirectory)
        try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
    
    @Test func basicRecursiveTest() throws {
        var testRoot = MkdirTest.newTemporaryRoot()
        defer {
            try? FileManager.default.removeItem(at: testRoot)
        }
                
        MkdirTest.logger.info("Test root: \(testRoot.absoluteString)")
        
        let attributeRequest = FSItem.SetAttributesRequest()
        
        let expectedModifyTimeSource = Calendar.current.date(byAdding: .hour, value: -1, to: Date.now)!
        let expectedModifyTime = timespec(from: expectedModifyTimeSource)
        let expectedMode: UInt32 = 0o777
        
        attributeRequest.gid = getgid()
        attributeRequest.uid = getuid()
        attributeRequest.mode = expectedMode
        attributeRequest.modifyTime = expectedModifyTime
        attributeRequest.accessTime = expectedModifyTime
        
        testRoot.append(path: "hello/world/whats/up", directoryHint: .isDirectory)
        
        MkdirTest.logger.info("Test path \(testRoot.path(percentEncoded: false))")
        
        try mkdirPlus(at: testRoot.path(percentEncoded: false), recursive: true, attributes: attributeRequest)
        
        let dirExists = FileManager.default.fileExists(atPath: testRoot.path(percentEncoded: false))
        
        try #require(dirExists)
        
        let attributes = try FileManager.default.attributesOfItem(atPath: testRoot.path(percentEncoded: false))
        
        let mTimeAsDate = attributes[.modificationDate] as? Date
        
        try #require(mTimeAsDate != nil)
        
        try #require(Calendar.current.isDate(mTimeAsDate!, equalTo: expectedModifyTimeSource, toGranularity: .second))
    }
    
    @Test func failToCreateExistingDirectory() throws {
        var testRoot = MkdirTest.newTemporaryRoot()
        defer {
            try? FileManager.default.removeItem(at: testRoot)
        }
                
        MkdirTest.logger.info("Test root: \(testRoot.absoluteString)")
        
        testRoot.append(path: "hello/world/whats/up", directoryHint: .isDirectory)
        
        MkdirTest.logger.info("Test path \(testRoot.path(percentEncoded: false))")
        
        let attributeRequest = FSItem.SetAttributesRequest()
        
        attributeRequest.gid = getgid()
        attributeRequest.uid = getuid()
        attributeRequest.mode = 0o777
        
        try mkdirPlus(at: testRoot.path(percentEncoded: false), recursive: true, attributes: attributeRequest)
        
        try #require(throws: NSError(domain: NSPOSIXErrorDomain, code: Int(POSIXError.EEXIST.rawValue))) {
            try mkdirPlus(at: testRoot.path(percentEncoded: false), recursive: true, attributes: attributeRequest)
        }
    }
}
