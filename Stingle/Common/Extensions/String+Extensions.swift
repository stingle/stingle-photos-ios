import UIKit

extension String {
    
    static func localized(for key: String, replaceValue comment: String) -> String {
        let fallbackLanguage = "en"
        let fallbackBundlePath = Bundle.main.path(forResource: fallbackLanguage, ofType: "lproj")
        let fallbackBundle = Bundle(path: fallbackBundlePath!)
        let fallbackString = fallbackBundle?.localizedString(forKey: key, value: comment, table: nil)
        let localizedString = Bundle.main.localizedString(forKey: key, value: fallbackString, table: nil)
        
        return localizedString
    }
    
    var localized: String {
        return String.localized(for: self, replaceValue: "")
    }
}

extension NSMutableAttributedString {
    
    func setColor(color: UIColor, forText stringValue: String) {
        let range: NSRange = self.mutableString.range(of: stringValue, options: .caseInsensitive)
        self.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
    }
    
    func setFont(font:UIFont, forText stringValue: String) {
        let range: NSRange = self.mutableString.range(of: stringValue, options: .caseInsensitive)
        self.addAttribute(NSAttributedString.Key.font, value: font, range: range)
    }
	
}
