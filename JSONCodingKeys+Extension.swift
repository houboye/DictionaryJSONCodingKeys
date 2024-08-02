import UIKit

public struct JSONCodingKeys: CodingKey {
    public var stringValue: String

    public init?(stringValue: String) {
        self.stringValue = stringValue
    }

    public var intValue: Int?

    public init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

public extension KeyedEncodingContainer {
    public mutating func encode(_ value: JsonAble?, forKey key: K) throws {
        try self.encode(value?.jsonStr, forKey: key)
    }
}

public extension KeyedDecodingContainer {

    public func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> [String: Any] {
        if let container = try? self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key) {
            return try container.decode(type)
        } else {
            let jsonString = try self.decode(String.self, forKey: key)
            return try jsonString.convertJSONStringToDict() ?? [:]
        }
    }

    public func decodeIfPresent(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> [String: Any]? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    public func decode(_ type: Array<Any>.Type, forKey key: K) throws -> [Any] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    public func decode(_ type: Array<Array<Any>>.Type, forKey key: K) throws -> [[Any]] {
        var unkeyedContainer = try self.nestedUnkeyedContainer(forKey: key)
        var nestedArrays: [[Any]] = []
        while !unkeyedContainer.isAtEnd {
            var nestedUnkeyedContainer = try unkeyedContainer.nestedUnkeyedContainer()
            if let result = try? nestedUnkeyedContainer.decode(Array<Any>.self) {
                nestedArrays.append(result)
            }
        }
        return nestedArrays
    }
    
    public func decode(_ type: [[[String: Any]]].Type, forKey key: K) throws -> [[[String: Any]]] {
        if var unkeyedContainer = try? self.nestedUnkeyedContainer(forKey: key) {
            var nestedArrays: [[[String: Any]]] = []
            while !unkeyedContainer.isAtEnd {
                var nestedUnkeyedContainer = try unkeyedContainer.nestedUnkeyedContainer()
                if let result = try? nestedUnkeyedContainer.decode(Array<Any>.self) as? [[String: Any]] {
                    nestedArrays.append(result)
                }
            }
            return nestedArrays
        } else {
            let jsonString = try self.decode(String.self, forKey: key)
            return try jsonString.convertJSONStringToArray() as? [[[String: Any]]] ?? []
        }
    }

    public func decodeIfPresent(_ type: Array<Any>.Type, forKey key: K) throws -> [Any]? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    public func decode(_ type: Dictionary<String, Any>.Type) throws -> [String: Any] {
        var dictionary = [String: Any]()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

public extension UnkeyedDecodingContainer {

    mutating public func decode(_ type: Array<Any>.Type) throws -> [Any] {
        var array: [Any] = []
        while isAtEnd == false {
            // See if the current value in the JSON array is `null` first and prevent infite recursion with nested arrays.
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode(Array<Any>.self) {
                array.append(nestedArray)
            }
        }
        return array
    }

    mutating public func decode(_ type: Dictionary<String, Any>.Type) throws -> [String: Any] {

        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}

public extension KeyedEncodingContainerProtocol where Key == JSONCodingKeys {
    public mutating func encode(_ value: Dictionary<String, Any>) throws {
        try value.forEach({ (key, value) in
            if let key = JSONCodingKeys(stringValue: key) {
                switch value {
                case let value as Bool:
                    try encode(value, forKey: key)
                case let value as Int:
                    try encode(value, forKey: key)
                case let value as String:
                    try encode(value, forKey: key)
                case let value as Double:
                    try encode(value, forKey: key)
                case let value as Dictionary<String, Any>:
                    try encode(value, forKey: key)
                case let value as Array<Any>:
                    try encode(value, forKey: key)
                case Optional<Any>.none:
                    try encodeNil(forKey: key)
                default:
                    throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath + [key], debugDescription: "Invalid JSON value"))
                }
            }
        })
    }
}

public extension KeyedEncodingContainerProtocol {
    public mutating func encode(_ value: Dictionary<String, Any>?, forKey key: Key) throws {
        if value != nil {
            var container = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
            try container.encode(value!)
        }
    }

    public mutating func encode(_ value: Array<Any>?, forKey key: Key) throws {
        if value != nil {
            var container = self.nestedUnkeyedContainer(forKey: key)
            try container.encode(value!)
        }
    }
}

public extension UnkeyedEncodingContainer {
    public mutating func encode(_ value: Array<Any>) throws {
        try value.enumerated().forEach({ (index, value) in
            switch value {
            case let value as Bool:
                try encode(value)
            case let value as Int:
                try encode(value)
            case let value as String:
                try encode(value)
            case let value as Double:
                try encode(value)
            case let value as Dictionary<String, Any>:
                try encode(value)
            case let value as Array<Any>:
                try encode(value)
            case Optional<Any>.none:
                try encodeNil()
            default:
                let keys = JSONCodingKeys(intValue: index).map({ [$0] }) ?? []
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath + keys, debugDescription: "Invalid JSON value"))
            }
        })
    }

    public mutating func encode(_ value: Dictionary<String, Any>) throws {
        var nestedContainer = self.nestedContainer(keyedBy: JSONCodingKeys.self)
        try nestedContainer.encode(value)
    }
}
