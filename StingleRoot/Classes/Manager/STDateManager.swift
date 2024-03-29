//
//  STDateManager.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/15/21.
//

import Foundation

public class STDateManager {
    
    static public let shared = STDateManager()
    
    private init() { }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        return formatter
    }()
    
    public func dateToString(date: Date?, withFormate format: DateFormat) -> String {
        guard date != nil else {
            return ""
        }
        self.dateFormatter.dateFormat = format.rawValue
        return self.dateFormatter.string(from: date!)
    }

    public func dateToString(date: Date, format: String) -> String {
        self.dateFormatter.dateFormat = format
        return self.dateFormatter.string(from: date)
    }
    
    public func stringToDate(dateString: String, format: DateFormat) -> Date? {
        self.dateFormatter.dateFormat = format.rawValue
        let date = self.dateFormatter.date(from: dateString)
        return date
    }
    
}

public extension STDateManager {
    
    enum DateFormat: String {
        case dd_mm_yyyy_HH_mm = "dd-MM-yyyy HH:mm"
        case mmm_dd_yyyy = "MMM dd, yyyy"
        case HH_mm = "HH:mm"
        case dd_mmm_yyyy = "dd MMM yyyy"
    }

}
