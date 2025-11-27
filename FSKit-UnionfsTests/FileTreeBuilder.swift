//
//  FileStubCreator.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 26.11.25.
//

import Foundation

protocol TestFileTreeItem {
    var parent: TestFileTreeItem? { get set }
    var name: String { get set }
}

class TestDir: TestFileTreeItem {
    var name: String
    var parent: (TestFileTreeItem)?
    var childs: [TestFileTreeItem] = []
    var attributes: [FileAttributeKey: Any]? = nil
    
    init(name: String) {
        self.name = name
    }
    
    convenience init(_ name: String) {
        self.init(name: name)
    }
    
    convenience init(_ name: String, attributes: [FileAttributeKey: Any]) {
        self.init(name: name)
        self.attributes = attributes
    }
    
    convenience init(_ name: String, @FileTreeBuilder _ childs: @escaping () -> [TestFileTreeItem]) {
        self.init(name: name)
        self.childs = childs()
        for var child in self.childs {
            child.parent = self
        }
    }
    
    convenience init(_ name: String, attributes: [FileAttributeKey: Any], @FileTreeBuilder _ childs: @escaping () -> [TestFileTreeItem]) {
        self.init(name: name)
        self.childs = childs()
        for var child in self.childs {
            child.parent = self
        }
        self.attributes = attributes
    }
        
    func writeTree(to url: URL) -> URL {
        let dirUrl = url.appending(path: self.name, directoryHint: .isDirectory)
        try! FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true, attributes: self.attributes)
        for child in childs {
            if let file = child as? TestFile {
                let fileUrl = dirUrl.appending(path: file.name, directoryHint: .notDirectory)
                FileManager.default.createFile(atPath: fileUrl.path(percentEncoded: false), contents: file.content.data(using: .utf8), attributes: file.attributes)
            } else if let dir = child as? TestDir {
                let _ = dir.writeTree(to: dirUrl)
            }
        }
        return dirUrl
    }
}

class TestFile: TestFileTreeItem {
    var parent: (any TestFileTreeItem)?
    var name: String
    var content: String = ""
    var attributes: [FileAttributeKey: Any]? = nil
    
    init(name: String, content: String) {
        self.name = name
        self.content = content
    }
    
    convenience init(_ name: String) {
        self.init(name: name, content: "")
    }
    
    convenience init(_ name: String, attributes: [FileAttributeKey: Any]) {
        self.init(name: name, content: "")
        self.attributes = attributes
    }
    
    convenience init(_ name: String, content: String) {
        self.init(name: name, content: content)
    }
    
    convenience init(_ name: String, content: String, attributes: [FileAttributeKey: Any]) {
        self.init(name: name, content: content)
        self.attributes = attributes
    }
}

@resultBuilder
struct FileTreeBuilder {
    static func buildBlock(_ components: [any TestFileTreeItem]...) -> [any TestFileTreeItem] {
        components.flatMap({ $0 })
    }
    
    static func buildExpression(_ expression: any TestFileTreeItem) -> [any TestFileTreeItem] {
        [expression]
    }
    
    static func buildExpression(_ expression: [any TestFileTreeItem]) -> [any TestFileTreeItem] {
        expression
    }
}
