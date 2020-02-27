//
//  FileManger.swift
//  Stingle
//
//  Created by Davit Grigoryan on 26.02.2020.
//  Copyright © 2020 Davit Grigoryan. All rights reserved.
//

import Foundation

class SPFileManager : FileManager {
    
    private static var storagePath:URL? {
        get {
            guard let path = self.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
                return nil
            }
            return path
        }
    }
    
    public static func fullPathOfFile(fileName:String) -> URL? {
        guard let fullPath = (SPFileManager.storagePath?.appendingPathComponent(fileName)) else {
            return nil
        }
        return fullPath
    }
}
