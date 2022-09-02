//
//  UIFont+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/30/21.
//

import UIKit

extension UIFont {
    
    class func light(light size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .light)
    }
    
    class func ultraLight(light size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .ultraLight)
    }
    
    class func thin(light size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .thin)
    }
    
    class func regular(light size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .regular)
    }
    
    class func medium(light size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .medium)
    }
    
    class func semibold(light size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .semibold)
    }
    
    class func bold(light size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .bold)
    }
    
    class func heavy(light size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .heavy)
    }
    
    class func black(light size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .black)
    }

}
