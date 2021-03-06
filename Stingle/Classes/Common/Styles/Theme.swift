import UIKit

struct Theme {
	
    struct Colors {
		
        static var SPDarkRed: UIColor { return #colorLiteral(red: 0.4980392157, green: 0, blue: 0, alpha: 1)}
        static var SPRed: UIColor { return #colorLiteral(red: 0.7176470588, green: 0.1098039216, blue: 0.1098039216, alpha: 1)}
		static var SPLightRed:UIColor { return #colorLiteral(red: 0.7254901961, green: 0.2235294118, blue: 0.2235294118, alpha: 1)}
        static var SPLightGray: UIColor { return #colorLiteral(red: 0.8745098039, green: 0.8745098039, blue: 0.8745098039, alpha: 1)}
        static var SPBlackOpacity87: UIColor { return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.87)}
        static var SPBlackOpacity12: UIColor { return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.12)}
		
    }
    
    struct Fonts {
        static func SFProMedium(size:CGFloat) -> UIFont {
            return  .medium(light: size)
        }
        static func SFProRegular(size:CGFloat) -> UIFont {
            return .regular(light: size)
        }
        static func SFProBold(size:CGFloat) -> UIFont {
            return .bold(light: size)
        }
        static func SFProSemibold(size:CGFloat) -> UIFont {
            return .semibold(light: size)
        }
        static func SFProHeavy(size:CGFloat) -> UIFont {
            return .heavy(light: size)
        }

    }
}

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
