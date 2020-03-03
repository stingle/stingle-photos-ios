import UIKit

struct Theme {
    struct Colors {
        static var SPDarkRed: UIColor { return #colorLiteral(red: 0.4980392157, green: 0, blue: 0, alpha: 1)}
        static var SPRed: UIColor { return #colorLiteral(red: 0.7176470588, green: 0.1098039216, blue: 0.1098039216, alpha: 1)}
        static var SPLightGray: UIColor { return #colorLiteral(red: 0.8745098039, green: 0.8745098039, blue: 0.8745098039, alpha: 1)}
        static var SPBlackOpacity87: UIColor { return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.87)}
    }
    
    struct Fonts {
        static func SFProMedium(size:CGFloat) -> UIFont {
            return UIFont(name: "SFProDisplay-Medium", size: size)!
        }
        static func SFProRegular(size:CGFloat) -> UIFont {
            return UIFont(name: "SFProDisplay-Regular", size: size)!
        }
        static func SFProBold(size:CGFloat) -> UIFont {
            return UIFont(name: "SFProDisplay-Bold", size: size)!
        }
        static func SFProSemibold(size:CGFloat) -> UIFont {
            return UIFont(name: "SFProDisplay-Semibold", size: size)!
        }
        static func SFProHeavy(size:CGFloat) -> UIFont {
            return UIFont(name: "SFProDisplay-Heavy", size: size)!
        }
        
        
        
    }
}
