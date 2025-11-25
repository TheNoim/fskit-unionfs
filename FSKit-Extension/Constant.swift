//
//  Constant.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 22.11.25.
//
import Foundation

enum Constants {
    static let extensionIdentifier = "io.noim.FSKit-Unionfs.FSKit-Extension"

    static let containerIdentifier: UUID = UUID(uuidString: "2feda794-d5fc-44e8-b139-a5d7d7a9dad7")!
    
    static let urlProtocolSchema = {
        if let attrs = Bundle.main.object(forInfoDictionaryKey: "EXAppExtensionAttributes") as? [String: Any],
           let schemes = attrs["FSSupportedSchemes"] as? [String],
           let first = schemes.first {
            return first
        }
        return "unionfs"
    }()
    
    static let shortName = {
        if let attrs = Bundle.main.object(forInfoDictionaryKey: "EXAppExtensionAttributes") as? [String: Any],
           let shortname = attrs["FSShortName"] as? String {
            return shortname
        }
        return "unionfs"
    }()
}
