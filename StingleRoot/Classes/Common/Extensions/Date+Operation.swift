import Foundation

public extension Date {
    
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

public extension TimeInterval {
    
    func timeFormat() -> String {
        let ti = Int(self)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        if hours > 0 {
            return String(format: "%0.2d:%0.2d:%0.2d%", hours, minutes, seconds)
        }
        return String(format: "%0.2d:%0.2d%", minutes, seconds)
    }
    
}

