//
//  TransferableFileAttributes.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 23.11.25.
//

import Foundation

@objc(TransferableFileAttributes)
public final class TransferableFileAttributes: NSObject, Sendable, Codable, NSSecureCoding {
    public let type: FileAttributeType?
    public let size: UInt64?
    public let creationDate: Date?
    public let modificationDate: Date?
    public let ownerAccountID: UInt32?
    public let groupOwnerAccountID: UInt32?
    
    init(raw: [FileAttributeKey: Any]) {
        self.type = raw[.type] as? FileAttributeType
        if let n = raw[.size] as? NSNumber {
            self.size = n.uint64Value
        } else if let s = raw[.size] as? UInt64 {
            self.size = s
        } else {
            self.size = nil
        }
        self.creationDate = raw[.creationDate] as? Date ?? (raw[.creationDate] as? NSDate as Date?)
        self.modificationDate = raw[.modificationDate] as? Date ?? (raw[.modificationDate] as? NSDate as Date?)
        if let n = raw[.ownerAccountID] as? NSNumber {
            self.ownerAccountID = n.uint32Value
        } else if let v = raw[.ownerAccountID] as? UInt32 {
            self.ownerAccountID = v
        } else {
            self.ownerAccountID = nil
        }
        if let n = raw[.groupOwnerAccountID] as? NSNumber {
            self.groupOwnerAccountID = n.uint32Value
        } else if let v = raw[.groupOwnerAccountID] as? UInt32 {
            self.groupOwnerAccountID = v
        } else {
            self.groupOwnerAccountID = nil
        }
    }
    
    // If you still need a dictionary for legacy consumers, you can expose this:
    var asRawDictionary: [FileAttributeKey: Any] {
        var d: [FileAttributeKey: Any] = [:]
        if let type { d[.type] = type }
        if let size { d[.size] = size }
        if let creationDate { d[.creationDate] = creationDate }
        if let modificationDate { d[.modificationDate] = modificationDate }
        if let ownerAccountID { d[.ownerAccountID] = ownerAccountID }
        if let groupOwnerAccountID { d[.groupOwnerAccountID] = groupOwnerAccountID }
        return d
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case size
        case creationDate
        case modificationDate
        case ownerAccountID
        case groupOwnerAccountID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Bridge FileAttributeType via its rawValue (String)
        if let type {
            try container.encode(type.rawValue, forKey: .type)
        }
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(creationDate, forKey: .creationDate)
        try container.encodeIfPresent(modificationDate, forKey: .modificationDate)
        try container.encodeIfPresent(ownerAccountID, forKey: .ownerAccountID)
        try container.encodeIfPresent(groupOwnerAccountID, forKey: .groupOwnerAccountID)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode FileAttributeType from its rawValue String
        if let rawType = try container.decodeIfPresent(String.self, forKey: .type) {
            self.type = FileAttributeType(rawValue: rawType)
        } else {
            self.type = nil
        }
        self.size = try container.decodeIfPresent(UInt64.self, forKey: .size)
        self.creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate)
        self.modificationDate = try container.decodeIfPresent(Date.self, forKey: .modificationDate)
        self.ownerAccountID = try container.decodeIfPresent(UInt32.self, forKey: .ownerAccountID)
        self.groupOwnerAccountID = try container.decodeIfPresent(UInt32.self, forKey: .groupOwnerAccountID)
        super.init()
    }
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool { true }
    
    public func encode(with coder: NSCoder) {
        // Encode FileAttributeType via rawValue
        if let type {
            coder.encode(type.rawValue as NSString, forKey: CodingKeys.type.rawValue)
        }
        if let size {
            coder.encode(NSNumber(value: size), forKey: CodingKeys.size.rawValue)
        }
        if let creationDate {
            coder.encode(creationDate as NSDate, forKey: CodingKeys.creationDate.rawValue)
        }
        if let modificationDate {
            coder.encode(modificationDate as NSDate, forKey: CodingKeys.modificationDate.rawValue)
        }
        if let ownerAccountID {
            coder.encode(NSNumber(value: ownerAccountID), forKey: CodingKeys.ownerAccountID.rawValue)
        }
        if let groupOwnerAccountID {
            coder.encode(NSNumber(value: groupOwnerAccountID), forKey: CodingKeys.groupOwnerAccountID.rawValue)
        }
    }
    
    public required init?(coder: NSCoder) {
        // Decode FileAttributeType from rawValue String
        if let rawType = coder.decodeObject(of: NSString.self, forKey: CodingKeys.type.rawValue) as String? {
            self.type = FileAttributeType(rawValue: rawType)
        } else {
            self.type = nil
        }
        
        if let n = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.size.rawValue) {
            self.size = n.uint64Value
        } else {
            self.size = nil
        }
        
        self.creationDate = coder.decodeObject(of: NSDate.self, forKey: CodingKeys.creationDate.rawValue) as Date?
        self.modificationDate = coder.decodeObject(of: NSDate.self, forKey: CodingKeys.modificationDate.rawValue) as Date?
        
        if let n = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.ownerAccountID.rawValue) {
            self.ownerAccountID = n.uint32Value
        } else {
            self.ownerAccountID = nil
        }
        
        if let n = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.groupOwnerAccountID.rawValue) {
            self.groupOwnerAccountID = n.uint32Value
        } else {
            self.groupOwnerAccountID = nil
        }
        
        super.init()
    }
}
