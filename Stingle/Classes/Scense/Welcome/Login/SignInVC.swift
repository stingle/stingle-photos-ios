import UIKit

class SignInVC: UITableViewController {
	
	private let viewModel = SignInVM()

	@IBOutlet weak var emailInput: UITextField!
	@IBOutlet weak var emailSeparator: UIView!
	@IBOutlet weak var passwordInput: UITextField!
	@IBOutlet weak var passwordSeparator: UIView!
	@IBOutlet weak var forgotPassword: UIButton!
	@IBOutlet weak var signIn: UIButton!
	@IBOutlet weak var signUp: UIButton!
	@IBOutlet weak var dontHaveAnAccount: UILabel!
	
	@IBAction func singInClicked(_ sender: Any) {
		
//		self.viewModel.signIn(email: <#T##String?#>, password: self.passwordInput.text, success: <#T##((User) -> Void)##((User) -> Void)##(User) -> Void#>, failure: <#T##((IError) -> Void)##((IError) -> Void)##(IError) -> Void#>)
		

	}
	
	@IBAction func signUpClicked(_ sender: Any) {
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		emailInput.delegate = self
		passwordInput.delegate = self
		createBackBarButton(forNavigationItem: self.navigationItem)
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
		let backButtonImage = UIImage(named: "chevron.left")
		let backBarButton = UIBarButtonItem(image: backButtonImage, style: .plain, target: self, action: #selector(backButtonTapped))
		backBarButton.tintColor = .white
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
