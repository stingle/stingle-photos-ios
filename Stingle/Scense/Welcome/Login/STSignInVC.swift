import UIKit

class STSignInVC: UITableViewController {
	
	private let viewModel = STSignInVM()
    private var appPassword: String?

	@IBOutlet weak var emailTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var forgotPassword: UIButton!
	@IBOutlet weak var signInButton: UIButton!
	@IBOutlet weak var signUpButton: UIButton!
	@IBOutlet weak var dontHaveAnAccount: UILabel!
    
    @IBAction func didSelectSingInButton(_ sender: Any) {
		self.login()
	}
	
	@IBAction func didSelectSingUpButton(_ sender: Any) {
		guard let navigationController = self.navigationController else {
			return
		}
		let signInVC = self.storyboard!.instantiateViewController(withIdentifier: "SignUpVC")
		UIView.transition(with: navigationController.view, duration: 0.5, options: .transitionFlipFromRight, animations: {
			navigationController.popViewController(animated: false)
			navigationController.pushViewController(signInVC, animated: false)
		}, completion:nil)
	}
	
	//MARK: - Override func
	 
	override func viewDidLoad() {
		super.viewDidLoad()
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
		return UITableView.automaticDimension
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
	
	//MARK: - Private func
	
	private func login() {
		self.tableView.endEditing(true)
        
        let view: UIView = self.navigationController?.view ?? self.view
		STLoadingView.show(in: view)
		self.viewModel.login(email:  self.emailTextField.text, password: self.passwordTextField.text) { [weak self] (user, appPassword) in
            self?.appPassword = appPassword
            if user.isKeyBackedUp {
                self?.performSegue(withIdentifier: "goToHome", sender: nil)
            } else {
                self?.showBackupInputPhraseView()
            }
            STLoadingView.hide(in: view)
		} failure: { [weak self] (error) in
			STLoadingView.hide(in: view)
			self?.showError(error: error)
		}
	}
	
	private func configurebBackBarButton() {
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_chevron_left"), style: .done, target: self, action: #selector(self.backButtonTapped))
	}
	
	private func configureLocalizable() {
		self.emailTextField.placeholder = "email".localized
		self.passwordTextField.placeholder = "password".localized
		self.dontHaveAnAccount.text = "dont_have_an_accout".localized
		self.navigationItem.title = "sign_in".localized
		self.signUpButton.setTitle("sign_up".localized, for: .normal)
		self.signInButton.setTitle("sign_in".localized, for: .normal)
		self.forgotPassword.setTitle("forgot_password?".localized, for: .normal)
	}
	
	@objc private func backButtonTapped() {
		self.navigationController?.popViewController(animated: true)
	}
    
    private func showBackupInputPhraseView() {
        let view: UIView = self.navigationController?.view ?? self.view
        let backupInputPhraseView = STBackupInputPhraseView.show(in: view)
        backupInputPhraseView.delegate = self
    }
    
}

extension STSignInVC : STBackupInputPhraseViewDelegate {
   
    func backupPhraseView(didSelectCancel backupPhraseView: STBackupInputPhraseView) {
        backupPhraseView.hide()
    }
    
    func backupPhraseView(didSelectOk backupPhraseView: STBackupInputPhraseView, text: String?) {
        backupPhraseView.hide()
        let view: UIView = self.navigationController?.view ?? self.view
        STLoadingView.show(in: view)
        self.viewModel.checkRecoveryPhrase(phrase: text, password: self.appPassword) { [weak self] error in
            STLoadingView.hide(in: view)
            
            if let error = error {
                self?.showError(error: error)
            } else {
                self?.performSegue(withIdentifier: "goToHome", sender: nil)
            }
            
        }
    }
    
}


extension STSignInVC : UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == self.emailTextField {
			self.passwordTextField.becomeFirstResponder()
		} else if textField == self.passwordTextField {
			self.login()
		}
		return true
	}
    
}
