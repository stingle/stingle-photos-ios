import UIKit

class SignInVC : BaseVC {
	
	private let viewModel = SignInVM()
	var dismissKeyboard:UIGestureRecognizer? = nil

	@IBOutlet weak var emailInput: UITextField!
	@IBOutlet weak var emailSeparator: UIView!
	@IBOutlet weak var passwordInput: UITextField!
	@IBOutlet weak var passwordSeparator: UIView!
	@IBOutlet weak var forgotPassword: UIButton!
	@IBOutlet weak var signIn: UIButton!
	@IBOutlet weak var signUp: UIButton!
	@IBOutlet weak var dontHaveAnAccount: UILabel!
	
	@IBAction func singInClicked(_ sender: Any) {
		_ = viewModel.signIn(email: "android@stingle.org", password: "mekicvec" ) { (status, error) in
//		_ = viewModel.signIn(email: emailInput.text, password: passwordInput.text ) { (status, error) in
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
	
	@IBAction func signUpClicked(_ sender: Any) {
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		emailInput.delegate = self
		passwordInput.delegate = self
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
	}
	
	//TODO : create reusable components (with style ) such as navigation bar, navigation bar items ... 
	func createBackBarButton(forNavigationItem navigationItem:UINavigationItem) {
		let backButtonImage = UIImage(named: "arrow_back")
		let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: backButtonImage!.size.width, height: backButtonImage!.size.height))
		backButton.setImage(backButtonImage!, for: .normal)
		backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
		let backBarButton = UIBarButtonItem(customView: backButton)
		let titleLabel = UILabel()
		let text = "landing_sign_in".localized
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

extension SignInVC : UITextFieldDelegate {
	
	@objc func hideKeyboard(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
		guard let responder = currentResponder() else {
			return
		}
		responder.resignFirstResponder()
	}

	func currentResponder() -> UITextField? {
		if emailInput.isFirstResponder {return emailInput}
		if passwordInput.isFirstResponder {return passwordInput}
		return nil
	}
	
	func separator(for textField:UITextField) -> UIView? {
		if textField == emailInput {
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
		if textField == emailInput {
			passwordInput.becomeFirstResponder()
		} else if textField == passwordInput {
			passwordInput.resignFirstResponder()
		}
		return true
	}
}
