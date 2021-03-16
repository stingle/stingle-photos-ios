import Foundation

extension Date {
    
    static var defaultDate: Date {
        return Date(milliseconds: 0)
    }
    
    var millisecondsSince1970: UInt64 {
        return UInt64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds: UInt64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
            
}
