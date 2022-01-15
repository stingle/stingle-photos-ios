import UIKit
import CryptoKit
import CommonCrypto

protocol StringPointer {
    var stringValue: String { get }
}

extension StringProtocol {
    
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
    subscript(range: Range<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
    subscript(range: ClosedRange<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
    subscript(range: PartialRangeFrom<Int>) -> SubSequence { self[index(startIndex, offsetBy: range.lowerBound)...] }
    subscript(range: PartialRangeThrough<Int>) -> SubSequence { self[...index(startIndex, offsetBy: range.upperBound)] }
    subscript(range: PartialRangeUpTo<Int>) -> SubSequence { self[..<index(startIndex, offsetBy: range.upperBound)] }
    
}

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
    
    var localizedUpper: String {
        return self.localized.uppercased()
    }
    
    var localizedCapitalizingedFirstLetter: String {
        return String.localized(for: self, replaceValue: "")
    }
    
    var capitalizingedFirstLetter: String {
        guard !self.isEmpty else { return "" }
        return self.prefix(1).uppercased() + self.lowercased().dropFirst()
    }
    
    var sha512: String? {
        guard let data = self.data(using: .utf8) else {
            return nil
            
        }
        let sh512 = SHA512.hash(data: data)
        let hashString = sh512.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
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
