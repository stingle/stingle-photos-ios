//
//  URL+Operation.swift
//  StingleRoot
//
//  Created by Khoren Asatryan on 11.07.22.
//

import Foundation

public extension URL {

    static func storeURL(for appGroup: String, databaseName: String) -> URL? {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            return nil
        }
        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
