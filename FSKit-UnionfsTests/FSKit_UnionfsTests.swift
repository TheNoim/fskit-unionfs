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

struct FSKit_UnionfsTests : ~Copyable {
    static let logger = Logger()
    
    static var createdRoots: [URL] = []
    
    static func newTemporaryRoot() -> URL {
        let temporaryDir = FileManager.default.temporaryDirectory
        let name = UUID().uuidString
        let root = temporaryDir.appending(path: name, directoryHint: .isDirectory)
        try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        createdRoots.append(root)
        return root
    }
    
    deinit {
        let commandRunner = CommandRunner()
        
        let _ = commandRunner.run(arguments: [
            "killall",
            "unionfs"
        ])
        
        for root in FSKit_UnionfsTests.createdRoots {
            try? FileManager.default.removeItem(at: root)
        }
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
        let temp = FSKit_UnionfsTests.newTemporaryRoot()
        defer {
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
        
        let commandRunner = CommandRunner()
        
        var mountComponents = URLComponents()
        mountComponents.scheme = "unionfs"
        mountComponents.host = "test"
        mountComponents.queryItems = [
            URLQueryItem(name: "br", value: testRoot.appending(path: "branch_a", directoryHint: .isDirectory).path(percentEncoded: false)),
            URLQueryItem(name: "br", value: testRoot.appending(path: "branch_b", directoryHint: .isDirectory).path(percentEncoded: false))
        ]
        
        let mntLocation = testRoot.appending(path: "mnt", directoryHint: .isDirectory).path(percentEncoded: false)
        
        try! await commandRunner.run(arguments: [
            "mount",
            "-t",
            "Unionfs",
            mountComponents.url!.absoluteString,
            mntLocation
        ]).awaitCompletion()
        
        #expect(FileManager.default.fileExists(atPath: testRoot.appending(path: "mnt/a.txt", directoryHint: .notDirectory).path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: testRoot.appending(path: "mnt/b.txt", directoryHint: .notDirectory).path(percentEncoded: false)))
        
        let originalFileAAttributes = try! FileManager.default.attributesOfItem(atPath: testRoot.appending(path: "branch_a/a.txt", directoryHint: .notDirectory).path(percentEncoded: false))
        let fileAMntAttributes = try! FileManager.default.attributesOfItem(atPath: testRoot.appending(path: "mnt/a.txt", directoryHint: .notDirectory).path(percentEncoded: false))
        
        let originalFileAOwner = originalFileAAttributes[.ownerAccountID] as! Int
        let unionFileOwner = fileAMntAttributes[.ownerAccountID] as! Int
    
        #expect(originalFileAOwner == unionFileOwner)
        
        let originalCreationDate = originalFileAAttributes[.creationDate] as! Date
        let unionCreationDate = fileAMntAttributes[.creationDate] as! Date
        
        #expect(originalCreationDate == unionCreationDate)
    
        
        try? await commandRunner.run(arguments: [
            "umount",
            "-f",
            mntLocation
        ]).awaitCompletion()
    }
    
    /// Test the branch sort algorithm
    @Test func testBranchPriorities() async throws {
        let temp = FSKit_UnionfsTests.newTemporaryRoot()
        defer {
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
        
        let commandRunner = CommandRunner()
        
        var mountComponents = URLComponents()
        mountComponents.scheme = "unionfs"
        mountComponents.host = "test"
        mountComponents.queryItems = [
            URLQueryItem(name: "br", value: testRoot.appending(path: "branch_a", directoryHint: .isDirectory).path(percentEncoded: false)),
            URLQueryItem(name: "br", value: testRoot.appending(path: "branch_b", directoryHint: .isDirectory).path(percentEncoded: false))
        ]
        
        let mntLocation = testRoot.appending(path: "mnt", directoryHint: .isDirectory).path(percentEncoded: false)
        
        try! await commandRunner.run(arguments: [
            "mount",
            "-t",
            "Unionfs",
            mountComponents.url!.absoluteString,
            mntLocation
        ]).awaitCompletion()
        
        #expect(FileManager.default.fileExists(atPath: testRoot.appending(path: "mnt/a.txt", directoryHint: .notDirectory).path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: testRoot.appending(path: "mnt/b.txt", directoryHint: .notDirectory).path(percentEncoded: false)))
        
        let originalBOnBranchAAttributes = try! FileManager.default.attributesOfItem(atPath: testRoot.appending(path: "branch_a/b.txt", directoryHint: .notDirectory).path(percentEncoded: false))
        
        let originalBOnBranchBAttributes = try! FileManager.default.attributesOfItem(atPath: testRoot.appending(path: "branch_b/b.txt", directoryHint: .notDirectory).path(percentEncoded: false))
        
        let bAttributesOnUnion = try! FileManager.default.attributesOfItem(atPath: testRoot.appending(path: "mnt/b.txt", directoryHint: .notDirectory).path(percentEncoded: false))
        
        let originalBOnBranchACreationDate = originalBOnBranchAAttributes[.creationDate] as! Date
        let originalBOnBranchBCreationDate = originalBOnBranchBAttributes[.creationDate] as! Date
        let creationDateBOnUnion = bAttributesOnUnion[.creationDate] as! Date
        
        #expect(originalBOnBranchACreationDate == creationDateBOnUnion)
        #expect(originalBOnBranchBCreationDate != creationDateBOnUnion)
        
        // a file should have a higher priority than a directory. Therfore, b/hello (file) should override a/hello/world.txt (file) even though branch a has a higher prio
        #expect(FileManager.default.fileExists(atPath: testRoot.appending(path: "mnt/hello/world.txt", directoryHint: .notDirectory).path(percentEncoded: false)) == false)
        
        try? await commandRunner.run(arguments: [
            "umount",
            "-f",
            mntLocation
        ]).awaitCompletion()
    }
}
