//
//  TransferableURLResourceValues.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 23.11.25.
//

import Foundation

@objc(TransferableURLResourceValues)
public final class TransferableURLResourceValues: NSObject, Codable, NSSecureCoding {
    public let volumeUUID: UUID?
    public let volumeName: String?
    public let volumeTotalCapacity: Int
    public let volumeAvailableCapacity: Int
    public let volumeSupportsImmutableFiles: Bool
    public let volumeSupportsCasePreservedNames: Bool?
    public let volumeSupportsCaseSensitiveNames: Bool?
    
    init(from values: URLResourceValues) {
        if let volumeUUIDString = values.volumeUUIDString {
            volumeUUID = UUID(uuidString: volumeUUIDString)
        } else {
            volumeUUID = nil
        }
        volumeName = values.volumeName ?? nil
        
        volumeTotalCapacity = values.volumeTotalCapacity ?? 0
        volumeAvailableCapacity = values.volumeAvailableCapacity ?? 0
        volumeSupportsImmutableFiles = values.volumeSupportsImmutableFiles ?? false
        volumeSupportsCasePreservedNames = values.volumeSupportsCasePreservedNames ?? nil
        volumeSupportsCaseSensitiveNames = values.volumeSupportsCaseSensitiveNames ?? nil
        super.init()
    }
    
    private enum CodingKeys: String, CodingKey {
        case volumeUUID
        case volumeName
        case volumeTotalCapacity
        case volumeAvailableCapacity
        case volumeSupportsImmutableFiles
        case volumeSupportsCasePreservedNames
        case volumeSupportsCaseSensitiveNames
    }
    
    // MARK: - Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let volumeUUID {
            try container.encode(volumeUUID.uuidString, forKey: .volumeUUID)
        }
        try container.encodeIfPresent(volumeName, forKey: .volumeName)
        try container.encode(volumeTotalCapacity, forKey: .volumeTotalCapacity)
        try container.encode(volumeAvailableCapacity, forKey: .volumeAvailableCapacity)
        try container.encode(volumeSupportsImmutableFiles, forKey: .volumeSupportsImmutableFiles)
        try container.encodeIfPresent(volumeSupportsCasePreservedNames, forKey: .volumeSupportsCasePreservedNames)
        try container.encodeIfPresent(volumeSupportsCaseSensitiveNames, forKey: .volumeSupportsCaseSensitiveNames)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let uuidString = try container.decodeIfPresent(String.self, forKey: .volumeUUID) {
            self.volumeUUID = UUID(uuidString: uuidString)
        } else {
            self.volumeUUID = nil
        }
        self.volumeName = try container.decodeIfPresent(String.self, forKey: .volumeName)
        self.volumeTotalCapacity = try container.decode(Int.self, forKey: .volumeTotalCapacity)
        self.volumeAvailableCapacity = try container.decode(Int.self, forKey: .volumeAvailableCapacity)
        self.volumeSupportsImmutableFiles = try container.decode(Bool.self, forKey: .volumeSupportsImmutableFiles)
        self.volumeSupportsCasePreservedNames = try container.decodeIfPresent(Bool.self, forKey: .volumeSupportsCasePreservedNames)
        self.volumeSupportsCaseSensitiveNames = try container.decodeIfPresent(Bool.self, forKey: .volumeSupportsCaseSensitiveNames)
        super.init()
    }
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool { true }
    
    public func encode(with coder: NSCoder) {
        if let volumeUUID {
            coder.encode(volumeUUID.uuidString as NSString, forKey: CodingKeys.volumeUUID.rawValue)
        }
        if let volumeName {
            coder.encode(volumeName as NSString, forKey: CodingKeys.volumeName.rawValue)
        }
        coder.encode(NSNumber(value: volumeTotalCapacity), forKey: CodingKeys.volumeTotalCapacity.rawValue)
        coder.encode(NSNumber(value: volumeAvailableCapacity), forKey: CodingKeys.volumeAvailableCapacity.rawValue)
        coder.encode(NSNumber(value: volumeSupportsImmutableFiles), forKey: CodingKeys.volumeSupportsImmutableFiles.rawValue)
        if let volumeSupportsCasePreservedNames {
            coder.encode(NSNumber(value: volumeSupportsCasePreservedNames), forKey: CodingKeys.volumeSupportsCasePreservedNames.rawValue)
        }
        if let volumeSupportsCaseSensitiveNames {
            coder.encode(NSNumber(value: volumeSupportsCaseSensitiveNames), forKey: CodingKeys.volumeSupportsCaseSensitiveNames.rawValue)
        }
    }
    
    public required init?(coder: NSCoder) {
        if let uuidString = coder.decodeObject(of: NSString.self, forKey: CodingKeys.volumeUUID.rawValue) as String? {
            self.volumeUUID = UUID(uuidString: uuidString)
        } else {
            self.volumeUUID = nil
        }
        self.volumeName = coder.decodeObject(of: NSString.self, forKey: CodingKeys.volumeName.rawValue) as String?
        
        if let n = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.volumeTotalCapacity.rawValue) {
            self.volumeTotalCapacity = n.intValue
        } else {
            self.volumeTotalCapacity = 0
        }
        if let n = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.volumeAvailableCapacity.rawValue) {
            self.volumeAvailableCapacity = n.intValue
        } else {
            self.volumeAvailableCapacity = 0
        }
        if let n = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.volumeSupportsImmutableFiles.rawValue) {
            self.volumeSupportsImmutableFiles = n.boolValue
        } else {
            self.volumeSupportsImmutableFiles = false
        }
        if let n = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.volumeSupportsCasePreservedNames.rawValue) {
            self.volumeSupportsCasePreservedNames = n.boolValue
        } else {
            self.volumeSupportsCasePreservedNames = nil
        }
        if let n = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.volumeSupportsCaseSensitiveNames.rawValue) {
            self.volumeSupportsCaseSensitiveNames = n.boolValue
        } else {
            self.volumeSupportsCaseSensitiveNames = nil
        }
        super.init()
    }
}
