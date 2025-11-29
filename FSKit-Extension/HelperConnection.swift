//
//  HelperConnection.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 23.11.25.
//

//import Foundation
//import XPC
//import FSKit
//
//class HelperConnection {
//    static let shared = HelperConnection()
//    
//    private var helperConnection: NSXPCConnection?
//    
//    private func getConnection() -> NSXPCConnection? {
//        if let connection = helperConnection {
//            return connection
//        }
//        
//        let connection = NSXPCConnection(machServiceName: helperIdentifier, options: .privileged)
//        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
//        connection.invalidationHandler = { [weak self] in
//            self?.helperConnection = nil
//        }
//        connection.resume()
//        helperConnection = connection
//        return connection
//    }
//    
//    var helper: HelperProtocol? {
//        guard let connection = getConnection() else {
//            return nil
//        }
//        
//        guard let proxy = connection.remoteObjectProxy as? HelperProtocol else {
//            return nil
//        }
//        
//        return proxy
//    }
//    
//    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) async throws -> [URL] {
//        guard let helper = helper else {
//            throw fs_errorForPOSIXError(POSIXError.EIO.rawValue)
//        }
//        
//        let urls = try await withCheckedThrowingContinuation() { cont in
//            helper.contentsOfDirectory(at: url, includingPropertiesForKeys: keys) { urls, error in
//                if let urlStrings = urls {
//                    let urls = urlStrings.map({ URL(string: $0) }).compactMap({ $0 })
//                    
//                    cont.resume(returning: urls)
//                } else if let error = error {
//                    cont.resume(throwing: error)
//                } else {
//                    cont.resume(throwing: fs_errorForPOSIXError(POSIXError.EIO.rawValue))
//                }
//            }
//        }
//        
//        return urls
//    }
//}
