//
//  main.swift
//  UnionFS-Helper
//
//  Created by Nils Bergmann on 23.11.25.
//

import Foundation
import XPC
import OSLog

class HelperDelegate: NSObject, NSXPCListenerDelegate {
    private let logger = Logger(subsystem: "UnionFSHelper", category: "HelperDelegate")
    
    // Accept new XPC connections by setting up the exported interface and object.
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Validate that the main app and helper app have the same code signing identity, otherwise return
//        guard isValidClient(connection: newConnection) else {
//            logger.error("❌ Rejected connection from unauthorized client")
//            return false
//        }

        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.exportedObject = Helper.shared
        newConnection.resume()
        return true
    }
    
    // Check that the codesigning matches between the main app and the helper app
    private func isValidClient(connection: NSXPCConnection) -> Bool {
        do {
            return try CodesignCheck.codeSigningMatches(pid: connection.processIdentifier)
        } catch {
            print("Helper code signing check failed with error: \(error)")
            return false
        }
    }
}

let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: helperIdentifier)
listener.delegate = delegate
listener.resume()
RunLoop.main.run()
