//
//  FSKit_UnionfsTests.swift
//  FSKit-UnionfsTests
//
//  Created by Nils Bergmann on 26.11.25.
//

import Testing
import Foundation
import OSLog
import Command

@Suite("Basic Test Suite")
class FSKit_UnionfsTests {
    static let logger = Logger()
        
    static func newTemporaryRoot() -> URL {
        let temporaryDir = FileManager.default.temporaryDirectory
        let name = UUID().uuidString
        let root = temporaryDir.appending(path: name, directoryHint: .isDirectory)
        try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
    
    init() {
        // I hate it
        TestHelper.kill_fskitd()
    }
    
    deinit {
        let _ = CommandRunner().run(arguments: [
            "killall",
            "unionfs"
        ])
    }

    @Test func testTreeBuilder() async throws {
        let target = FSKit_UnionfsTests.newTemporaryRoot()
        defer {
            try? FileManager.default.removeItem(at: target)
        }
    
        let childContent = "HIIIIII!!!!!"
        
        let testRoot = TestDir("root") {
            TestFile("hello.txt", content: "Hello world!")
            TestDir("Child Test") {
                TestFile("child.txt", content: childContent)
            }
        }.writeTree(to: target)
        
        let childPath = testRoot.appending(path: "Child Test/child.txt", directoryHint: .notDirectory)
        
        #expect(FileManager.default.fileExists(atPath: target.path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: childPath.path(percentEncoded: false)))
        #expect(try! String(contentsOf: childPath, encoding: .utf8) == childContent)
    }

    @Test func basicMountTest() async throws {
        let testHelper = TestHelper()
        let temp = FSKit_UnionfsTests.newTemporaryRoot()
        defer {
            testHelper.disposeSync()
            try? FileManager.default.removeItem(at: temp)
        }
        
        let fileContent = "Hello world"
        
        let testRoot = TestDir("test_root") {
            TestDir("mnt")
            TestDir("branch_a") {
                TestFile("a.txt", content: "\(fileContent) a")
            }
            TestDir("branch_b") {
                TestFile("b.txt", content: "\(fileContent) b")
            }
        }.writeTree(to: temp)
        
        let mntLocation = try await testHelper.mount(with: testRoot, mnt: "mnt", branches: [
            .init("branch_a"),
            .init("branch_b")
        ])
        
        try #require(FileManager.default.fileExists(atPath: testRoot.withPath("mnt/a.txt", directoryHint: .notDirectory)), "a.txt should exist in mnt location")
        try #require(FileManager.default.fileExists(atPath: testRoot.withPath("mnt/b.txt", directoryHint: .notDirectory)), "b.txt should exist in mnt location")
        
        let originalFileAAttributes = try! FileManager.default.attributesOfItem(atPath: testRoot.withPath("branch_a/a.txt", directoryHint: .notDirectory))
        let fileAMntAttributes = try! FileManager.default.attributesOfItem(atPath: mntLocation.withPath("a.txt", directoryHint: .notDirectory))
        
        let originalFileAOwner = originalFileAAttributes[.ownerAccountID] as! Int
        let unionFileOwner = fileAMntAttributes[.ownerAccountID] as! Int
    
        #expect(originalFileAOwner == unionFileOwner, "The owner id of the file in mnt should equal the original file")
        
        let originalCreationDate = originalFileAAttributes[.creationDate] as! Date
        let unionCreationDate = fileAMntAttributes[.creationDate] as! Date
        
        #expect(originalCreationDate == unionCreationDate, "The creation date of the mnt file should equal the original file")
    }
    
    /// Test the branch sort algorithm
    @Test func testBranchPriorities() async throws {
        let testHelper = TestHelper()
        let temp = FSKit_UnionfsTests.newTemporaryRoot()
        defer {
            testHelper.disposeSync()
            try? FileManager.default.removeItem(at: temp)
        }
     
        let fileContent = "Hello world"
        
        let testRoot = TestDir("test_root") {
            TestDir("mnt")
            TestDir("branch_a") {
                TestFile("a.txt", content: "\(fileContent) a")
                // should override branch_b/b.txt, because per default branch_a has the lower priority number, therfore the higher prio.
                TestFile("b.txt", content: "\(fileContent) a", attributes: [.creationDate: Date.distantPast])
                TestDir("hello") {
                    // branch_b has the lower priority, but because branch_b/hello is a file, it wins over this
                    TestFile("world.txt", content: "should exist")
                }
            }
            TestDir("branch_b") {
                TestFile("b.txt", content: "\(fileContent) b", attributes: [.creationDate: Date.distantFuture])
                TestFile("hello")
            }
        }.writeTree(to: temp)
        
        let mntLocation = try await testHelper.mount(with: testRoot, mnt: "mnt", branches: [
            .init("branch_a"),
            .init("branch_b")
        ])
        
        try #require(FileManager.default.fileExists(atPath: mntLocation.withPath("a.txt", directoryHint: .notDirectory)), "a.txt should exist in mnt location")
        try #require(FileManager.default.fileExists(atPath: mntLocation.withPath("b.txt", directoryHint: .notDirectory)), "b.txt should exist in mnt location")
        
        let originalBOnBranchAAttributes = try! FileManager.default.attributesOfItem(atPath: testRoot.withPath("branch_a/b.txt", directoryHint: .notDirectory))
        
        let originalBOnBranchBAttributes = try! FileManager.default.attributesOfItem(atPath: testRoot.withPath("branch_b/b.txt", directoryHint: .notDirectory))
        
        let bAttributesOnUnion = try! FileManager.default.attributesOfItem(atPath: mntLocation.withPath("b.txt", directoryHint: .notDirectory))
        
        let originalBOnBranchACreationDate = originalBOnBranchAAttributes[.creationDate] as! Date
        let originalBOnBranchBCreationDate = originalBOnBranchBAttributes[.creationDate] as! Date
        let creationDateBOnUnion = bAttributesOnUnion[.creationDate] as! Date
        
        #expect(originalBOnBranchACreationDate == creationDateBOnUnion)
        #expect(originalBOnBranchBCreationDate != creationDateBOnUnion)
        
        // a file should have a higher priority than a directory. Therfore, b/hello (file) should override a/hello/world.txt (file) even though branch a has a higher prio
        #expect(FileManager.default.fileExists(atPath: mntLocation.withPath("hello/world.txt", directoryHint: .notDirectory)) == false)
    }
}
