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

//extension CharacterSet {
//	static let urlQueryValueAllowed: CharacterSet = {
//		let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
//		let subDelimitersToEncode = "!$&'()*+,;="
//		var allowed = CharacterSet.urlQueryAllowed
//		allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
//		return allowed
//	}()
//}

//extension Sequence where Element == Character {  // Same as String
//
//	var byteArray: [UInt8] {
//		return String(self).utf8.map{UInt8($0)}
//	}
//
//	var shortArray: [UInt16] {
//		return String(self).utf16.map{UInt16($0)}
//	}
//
//}
