//
//  Codable+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/8/21.
//

import Foundation


extension Encodable {
    
    func toJson(encoder: JSONEncoder = JSONEncoder()) -> [String: Any]? {
        do {
            let data = try encoder.encode(self)
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            return json
        } catch {
            print(error)
        }
        return nil
    }
    
}

extension Dictionary {
    
    mutating func addIfNeeded(key: Key, value: Value?) {
        if let value = value {
            self[key] = value
        }
    }
    
}
