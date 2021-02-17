import UIKit

class SignUpVC: UITableViewController {
	
	private let viewModel = SignUpVM()
	
	@IBOutlet weak private var emailTextField: UITextField!
	@IBOutlet weak private var passwordTextField: UITextField!
	@IBOutlet weak private var confirmPasswordTextField: UITextField!
	
	@IBOutlet weak private var descriptionLabel: UILabel!
	@IBOutlet weak private var alreadyHaveAnAccountLabel: UILabel!
	@IBOutlet weak private var signUpButton: UIButton!
	@IBOutlet weak private var signInButton: UIButton!
	
	
	@IBAction func didSelectSignUp(_ sender: Any) {
		
		_ = viewModel.signUp(email: self.emailTextField.text, password: self.passwordTextField.text) { (status, error) in
			do {
				if status {
					SyncManager.update(completionHandler: { (status) in
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
	
	@IBAction func didSelectSignIn(_ sender: Any) {
		guard let navigationController = self.navigationController else {
			return
		}
		let signInVC = self.storyboard!.instantiateViewController(withIdentifier: "SignInVC")
		UIView.transition(with: navigationController.view, duration: 0.5, options: .transitionFlipFromRight, animations: {
			navigationController.popViewController(animated: false)
			navigationController.pushViewController(signInVC, animated: false)
		}, completion:nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configurebBackBarButton()
		self.configureLocalizable()
	}
	
	//MARK: private func
	
	private func configurebBackBarButton() {
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "chevron.left"), style: .done, target: self, action: #selector(self.backButtonTapped))
	}
	
	private func configureLocalizable() {
		self.emailTextField.placeholder = "email".localized
		self.passwordTextField.placeholder = "password".localized
		self.confirmPasswordTextField.placeholder = "confirm_password".localized
		self.descriptionLabel.text = "sign_up_description".localized
		self.alreadyHaveAnAccountLabel.text = "already_have_an_account".localized
		self.navigationItem.title = "sign_up".localized
		self.signUpButton.setTitle("sign_up".localized, for: .normal)
		self.signInButton.setTitle("sign_in".localized, for: .normal)
	}
	
	@objc private func backButtonTapped() {
		self.navigationController?.popViewController(animated: true)
	}
	
}

extension SignUpVC : UITextFieldDelegate {

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == self.confirmPasswordTextField {
			textField.resignFirstResponder()
		} else if textField == self.emailTextField {
			self.passwordTextField.becomeFirstResponder()
		} else if textField == self.passwordTextField {
			self.confirmPasswordTextField.becomeFirstResponder()
		}
		return true
	}
}
