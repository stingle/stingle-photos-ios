//
//  STLogger.swift
//  Stingle
//
//  Created by Khoren Asatryan on 30.05.22.
//

import Foundation

public class STLogger {
    
    private init() {}
    
    public static func log(logMessage: String, functionName: String = #function) {
        print("\(functionName): \(logMessage)")
    }
    
    public static func log(info: String, functionName: String = #function) {
        self.log(logMessage: "info: \(info)", functionName: functionName)
    }
    
    public static func log(error: IError, functionName: String = #function) {
        self.log(logMessage: "error: \(error.message)", functionName: functionName)
    }
    
    public static func log(logMessage: String, error: IError, functionName: String = #function) {
        self.log(logMessage: "\(logMessage) error: \(error.message) ", functionName: functionName)
    }
    
    public static func log(error: Error, functionName: String = #function) {
        self.log(logMessage: "error: \(STError.error(error: error))", functionName: functionName)
    }
}

