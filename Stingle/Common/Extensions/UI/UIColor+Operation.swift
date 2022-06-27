//
//  UIColor+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/25/21.
//

import UIKit

extension UIColor {
    
    class var appPrimary: UIColor {
        return UIColor(named: "STPrimary") ?? UIColor.black
    }
    
    class var primaryTransparent: UIColor {
        return UIColor(named: "STPrimaryTransparent") ?? UIColor.black
    }
        
    class var appBackground: UIColor {
        return UIColor(named: "STBackground") ?? UIColor.black
    }
    
    class var appErrorBackground: UIColor {
        return UIColor(named: "STErrorBackground") ?? UIColor.black
    }
    
    class var appText: UIColor {
        return UIColor(named: "STText") ?? UIColor.black
    }
    
    class var appSecondaryText: UIColor {
        return UIColor(named: "STSecondaryText") ?? UIColor.black
    }
        
    class var appPlaceholder: UIColor {
        return UIColor(named: "STPlaceholder") ?? UIColor.black
    }

    class var appYellow: UIColor {
        return UIColor(named: "STYellow") ?? UIColor.yellow
    }
    
}
