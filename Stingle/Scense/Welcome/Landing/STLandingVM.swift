import UIKit

class STLandingVM {
	
	private var index:Int = NSNotFound
	
	var page:Int {
		get {
			return index
		}
		set(newPage) {
			if newPage != index {
				index = newPage
			}
		}
	}
		
	public func image() -> UIImage? {
		guard let text = text() else {
			return nil
		}
		return UIImage(named: text)
	}
	
	public func descriptionTitle () -> NSAttributedString? {
		guard let text = text() else {
			return nil
		}
                
		let string = NSMutableAttributedString(string: "\(text)_title".localized)
        string.setFont(font: .medium(light: 20), forText: text)
		string.setColor(color: UIColor.appText, forText: text)
		return string
	}
	
	public func description () -> NSAttributedString? {
		guard let text = text() else {
			return nil
		}
		let string = NSMutableAttributedString(string: "\(text)_description".localized)
        string.setFont(font: .regular(light: 14), forText: text)
        string.setColor(color: UIColor.appText, forText: text)
		return string
	}
	
	public func signInTitle() -> NSAttributedString? {
		let text = "landing_sign_in".localized
		let string = NSMutableAttributedString(string: text)
        string.setFont(font: .medium(light: 14), forText: text)
		return string
	}
	
	public func signUpTitle() -> NSAttributedString? {
		let text = "landing_sign_up".localized
		let string = NSMutableAttributedString(string: text)
		string.setFont(font: .medium(light: 14), forText: text)
		return string
	}
	
	public func haveAnAccountTitle() -> NSAttributedString? {
		let text = "landing_have_an_account".localized
		let string = NSMutableAttributedString(string: text)
		string.setFont(font: .medium(light: 14), forText: text)
		string.setColor(color: UIColor.appText, forText: text)
		return string
	}
	
	private func text() -> String? {
		switch index {
		case 0:
			return "landing_trust_no_one"
		case 1:
			return "landing_true_privacy"
		case 2:
			return "landing_backup_and_sync"
		case 3:
			return "landing_fast_easy_to_use"
		default:
			break
		}
		return nil
	}	
}
