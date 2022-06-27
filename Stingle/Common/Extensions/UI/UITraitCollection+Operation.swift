//
//  UITraitCollection+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/15/21.
//

import UIKit

extension UITraitCollection {
    
    enum DeviceType: String {
        case ios = "ios"
        case iPad = "iPad"
        case tv = "tv"
    }
    
    class func isBothRegular() -> Bool {
        return UITraitCollection.current.isBothRegular()
    }
    
    class func isIpad() -> Bool {
        return self.isBothRegular()
    }
    
    class func isHorizontalIpad() -> Bool {
        let current = UITraitCollection.current
        if current.isTVOS() {
            return false
        }
        return current.isHorizontalIpad()
    }
    
    class var deviceType: DeviceType {
        return self.current.deviceType
    }
    
    func isBothRegular() -> Bool {
        return self.horizontalSizeClass == .regular && self.verticalSizeClass == .regular
    }

    func isBothCompact() -> Bool {
        return self.horizontalSizeClass == .compact && self.verticalSizeClass == .compact
    }

    func isWidthRegular() -> Bool {
        return self.horizontalSizeClass == .regular
    }

    func isHeightRegular() -> Bool {
        return self.verticalSizeClass == .regular
    }

    func isCompactRegular() -> Bool {
        return self.horizontalSizeClass == .compact && self.verticalSizeClass == .regular
    }

    func isTVOS() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .tv
    }
    
    func isIpad() -> Bool {
        if self.isTVOS() {
            return false
        }
        return self.isBothRegular()
    }
    
    func isHorizontalIpad() -> Bool {
        if self.isTVOS() {
            return false
        }
        return self.horizontalSizeClass == .regular
    }
    
    var deviceType: DeviceType {
        if self.isTVOS() {
            return .tv
        }
        if self.isIpad() {
            return .iPad
        }
        return .ios
    }
    
}

