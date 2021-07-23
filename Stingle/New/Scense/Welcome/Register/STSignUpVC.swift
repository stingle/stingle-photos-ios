import UIKit

class STSignUpVC: UITableViewController {
	
	private let viewModel = STSignUpVM()
	private var hiddenCells = Set<CellType>()
    private var appPassword: String?
	
	@IBOutlet weak private var emailTextField: UITextField!
	@IBOutlet weak private var passwordTextField: UITextField!
	@IBOutlet weak private var confirmPasswordTextField: UITextField!
	
	@IBOutlet weak private var descriptionLabel: UILabel!
	@IBOutlet weak private var alreadyHaveAnAccountLabel: UILabel!
	@IBOutlet weak private var signUpButton: UIButton!
	@IBOutlet weak private var signInButton: UIButton!
	@IBOutlet weak private var includePrivateKeySwitch: UISwitch!
	@IBOutlet weak private var advancedButton: UIButton!
	@IBOutlet weak private var backupMyKeysButton: UIButton!
	
	//MARK: User action
    
    @IBAction func didSelectbackupMyKeysButton(_ sender: UIButton) {
		self.showInfoAlert(title: "info".localized, message: "backup_my_keys_description".localized)
    }
	
	@IBAction func didSelectAdvancedButton(_ sender: UIButton) {
		var transform = CGAffineTransform.identity
		if self.hiddenCells.contains(.backupMyKeys) {
			self.hiddenCells.remove(.backupMyKeys)
			transform = .init(rotationAngle: CGFloat.pi / 2)
		}else {
			self.hiddenCells.insert(.backupMyKeys)
		}
		UIView.animate(withDuration: 0.3) {
			self.tableView.reloadRows(at: [IndexPath(row: CellType.backupMyKeys.rawValue, section: 0)], with: .bottom)
			sender.imageView?.transform = transform
		}
	}
	
	@IBAction func didSelectSignUp(_ sender: Any) {
		self.register()
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
	
	//MARK: Override func
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.hiddenCells.insert(.backupMyKeys)
		self.configurebBackBarButton()
		self.configureLocalizable()
	}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        (segue.destination as? STMenuVC)?.appPassword = self.appPassword
    }
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		var isHidden = false
		if let cellType = CellType(rawValue: indexPath.row) {
			isHidden = self.hiddenCells.contains(cellType)
		}
		return isHidden ? 0 : UITableView.automaticDimension
	}
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let view = UIView()
		view.backgroundColor = .clear
		return view
	}
	
	override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let view = UIView()
		view.backgroundColor = .clear
		return view
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = super.tableView(tableView, cellForRowAt: indexPath)
		var isHidden = false
		if let cellType = CellType(rawValue: indexPath.row) {
			isHidden = self.hiddenCells.contains(cellType)
		}
		cell.alpha = isHidden ? 0 : 1
		return cell
	}
	
	//MARK: Private func
	
	private func register() {
        
		self.tableView.endEditing(true)
		STLoadingView.show(in: self.navigationController?.view ?? self.view)
		
		let email = self.emailTextField.text
		let passwort = self.passwordTextField.text
		let includePrivateKey = self.includePrivateKeySwitch.isOn
		
		self.viewModel.registr(email: email, password: passwort, confirmPassword: self.confirmPasswordTextField.text, includePrivateKey: includePrivateKey) { [weak self] (user, appPassword) in
			guard let weakSelf = self else {
				return
			}
            weakSelf.appPassword = appPassword
			STLoadingView.hide(in: weakSelf.navigationController?.view ?? weakSelf.view)
			self?.performSegue(withIdentifier: "goToHome", sender: nil)
		} failure: { [weak self] (error) in
			guard let weakSelf = self else {
				return
			}
			STLoadingView.hide(in: weakSelf.navigationController?.view ?? weakSelf.view)
			self?.showError(error: error)
		}
	}
	
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
		self.advancedButton.setTitle("advanced".localized, for: .normal)
        self.backupMyKeysButton.setTitle("backup_my_keys".localized, for: .normal)
	}
	
	@objc private func backButtonTapped() {
		self.navigationController?.popViewController(animated: true)
	}
	
}

extension STSignUpVC : UITextFieldDelegate {

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == self.confirmPasswordTextField {
			self.register()
		} else if textField == self.emailTextField {
			self.passwordTextField.becomeFirstResponder()
		} else if textField == self.passwordTextField {
			self.confirmPasswordTextField.becomeFirstResponder()
		}
		return true
	}

}

extension STSignUpVC {

	private enum CellType: Int {
		case description
		case email
		case password
		case confirmPassword
		case advanced
		case backupMyKeys
	}

}

