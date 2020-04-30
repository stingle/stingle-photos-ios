import UIKit

class SignUpVC: BaseVC {
	
	private let viewModel = SignUpVM()
	var dismissKeyboard:UIGestureRecognizer? = nil

	
	@IBOutlet weak var top: NSLayoutConstraint!
	@IBOutlet weak var emailInput: UITextField!
	@IBOutlet var emailSeparator: UIView!
	@IBOutlet weak var passwordInput: UITextField!
	@IBOutlet weak var passwordSeparator: UIView!
	@IBOutlet weak var confirmPasswordInput: UITextField!
	@IBOutlet weak var confirmPasswordSeparator: UIView!
	@IBAction func signUpPressed(_ sender: Any) {
		_ = viewModel.signUp(email: emailInput.text, password: passwordInput.text) { (status, error) in
			do {
				if status {
					_ = SyncManager.update(completionHandler: { (status) in
						if status == true {
							DispatchQueue.main.async {
								let storyboard = UIStoryboard.init(name: "Home", bundle: nil)
								let home = storyboard.instantiateInitialViewController()
								self.navigationController?.pushViewController(home!, animated: false)
							}
						}
					})
				} else {
					print(error!)
				}
			}

		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		emailInput.delegate = self
		passwordInput.delegate = self
		confirmPasswordInput.delegate = self
		createBackBarButton(forNavigationItem: self.navigationItem)
		dismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
		self.view .addGestureRecognizer(dismissKeyboard!)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		guard let navigationController = self.navigationController else {
			return
		}
		navigationController.setNavigationBarHidden(false, animated: false)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)

	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self)
	}

	@objc func keyboardWillAppear() {
		top.constant = 0
	}

	@objc func keyboardWillDisappear() {
		top.constant = 67
		//Do something here
	}

	//TODO : create reusable components (with style ) such as navigation bar, navigation bar items ...
	func createBackBarButton(forNavigationItem navigationItem:UINavigationItem) {
		let backButtonImage = UIImage(named: "chevron.left")
		let backBarButton = UIBarButtonItem(image: backButtonImage, style: .plain, target: self, action: #selector(backButtonTapped))
		backBarButton.tintColor = .white
		let titleLabel = UILabel()
		let text = "landing_sign_up".localized
		let string = NSMutableAttributedString(string: text)
		string.setFont(font: Theme.Fonts.SFProMedium(size: 20), forText: text)
		string.setColor(color: .white, forText: text)
		titleLabel.attributedText = string
		let titleBar = UIBarButtonItem(customView: titleLabel)
		navigationItem.leftBarButtonItems = [backBarButton, titleBar]
	}
	
	@objc public func backButtonTapped() {
		self.navigationController?.popViewController(animated: true)
	}

}

extension SignUpVC : UITextFieldDelegate {
	
	@objc func hideKeyboard(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
		guard let responder = currentResponder() else {
			return
		}
		responder.resignFirstResponder()
	}

	func currentResponder() -> UITextField? {
		if emailInput.isFirstResponder {return emailInput}
		if passwordInput.isFirstResponder {return passwordInput}
		if confirmPasswordInput.isFirstResponder {return confirmPasswordInput}
		return nil
	}
	
	func separator(for textField:UITextField) -> UIView? {
		if textField == confirmPasswordInput {
			return confirmPasswordSeparator
		} else if textField == emailInput {
			return emailSeparator
		} else if textField == passwordInput {
			return passwordSeparator
		}
		return nil
	}
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		guard let separator = separator(for: textField) else {
			return
		}
		separator.backgroundColor = Theme.Colors.SPRed
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		guard let separator = separator(for: textField) else {
			return
		}
		separator.backgroundColor = Theme.Colors.SPLightGray
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == confirmPasswordInput {
			textField.resignFirstResponder()
		} else if textField == emailInput {
			passwordInput.becomeFirstResponder()
		} else if textField == passwordInput {
			confirmPasswordInput.becomeFirstResponder()
		}
		return true
	}
}
