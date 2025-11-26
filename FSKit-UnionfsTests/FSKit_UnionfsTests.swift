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

struct FSKit_UnionfsTests {
    static let logger = Logger()
    
    static func newTemporaryRoot() -> URL {
        let temporaryDir = FileManager.default.temporaryDirectory
        let name = UUID().uuidString
        let root = temporaryDir.appending(path: name, directoryHint: .isDirectory)
        try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
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
        
        try? await commandRunner.run(arguments: [
            "umount",
            "-f",
            mntLocation
        ]).awaitCompletion()
    }
}
