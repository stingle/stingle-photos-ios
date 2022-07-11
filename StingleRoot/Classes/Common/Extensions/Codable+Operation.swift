//
//  Codable+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import Foundation

extension Encodable {
    
    public func toJson(encoder: JSONEncoder = JSONEncoder()) -> [String: Any]? {
        do {
            let data = try encoder.encode(self)
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            return json
        } catch {
            STLogger.log(error: error)
        }
        return nil
    }
    
    public func toString() -> String? {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            let result = String(data: data, encoding: .utf8)
            return result
        } catch {
            STLogger.log(error: error)
        }
        return nil
    }
    
}

extension Decodable {
    
    public init?(from json: Any, decoder: JSONDecoder = JSONDecoder()) {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted), let result = try? decoder.decode(Self.self, from: data) else {
            return nil
        }
        self = result
    }
    
    public init?(from data: Data, decoder: JSONDecoder = JSONDecoder()) {
        guard let result = try? decoder.decode(Self.self, from: data) else {
            return nil
        }
        self = result
    }
    
}

extension Dictionary {
    
    public mutating func addIfNeeded(key: Key, value: Value?) {
        if let value = value {
            self[key] = value
        }
    }
    
}
