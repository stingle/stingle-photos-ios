//
//  STForgetPasswordVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/18/21.
//

import UIKit

class STForgetPasswordVC: UITableViewController {
   
    @IBOutlet weak private var emailTextField: STTextField!
    @IBOutlet weak private var phraseTextView: STTextView!
    @IBOutlet weak private var checkButton: STButton!
    
    weak private var newPasswordTextField: UITextField?
    weak private var confirmPasswordTextField: UITextField?
    weak private var resetPasswordAlert: UIAlertController?
    
    private let viewModel = STForgetPasswordVM()
    private var appPassword: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureLocalized()
    }
    
    //MARK: - Overrided methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        (segue.destination as? STMenuVC)?.appPassword = self.appPassword
        (segue.destination as? STMenuVC)?.isShowBackupPhrase = true
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
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
        let titleLabel = UILabel()
        titleLabel.textColor = .appText
        titleLabel.numberOfLines = .zero
        titleLabel.text = "forget_password_title".localized
        view.addSubviewFullContent(view: titleLabel, top: 8, right: 16, left: 16, bottom: 8)
        return view
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    //MARK: - Private methods
    
    private func configureLocalized() {
        self.emailTextField.placeholder = "email".localized
        self.phraseTextView.placeholder = "backup_phrase_input_placeholder".localized
        self.checkButton.setTitle("check".localized.uppercased(), for: .normal)
    }
    
    private func showResetPasswordAlert() {
        let title = "please_set_a_new_password".localized
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "ok".localized, style: .default) { [weak self] _ in
            self?.resetPassword(newPassword: alert.textFields?.first?.text, confirmPassword: alert.textFields?.last?.text)
        }
        
        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        
        alert.addTextField { [weak self] (textField) in
            textField.placeholder = "new_password".localized
            textField.isSecureTextEntry = true
            textField.textContentType = .newPassword
            textField.returnKeyType = .next
            textField.enablesReturnKeyAutomatically = true
            self?.newPasswordTextField = textField
        }
        
        alert.addTextField { [weak self] (textField) in
            textField.placeholder = "confirm_password".localized
            textField.isSecureTextEntry = true
            textField.returnKeyType = .done
            textField.enablesReturnKeyAutomatically = true
            self?.confirmPasswordTextField = textField
            textField.delegate = self
        }
        self.resetPasswordAlert = alert
        self.present(alert, animated: true, completion: nil)
    }
    
    private func resetPassword(newPassword: String?, confirmPassword: String?) {
        self.resetPasswordAlert?.dismiss(animated: true, completion: nil)
        let view: UIView = self.navigationController?.view ?? self.view
        STLoadingView.show(in: view)
        
        self.viewModel.recoverAccount(email: self.emailTextField.text, newPassword: newPassword, confirmPassword: confirmPassword) { [weak self] appPassword in
            self?.appPassword = appPassword
            STLoadingView.hide(in: view)
            self?.performSegue(withIdentifier: "goToHome", sender: nil)
        } failure: { [weak self] error in
            self?.showError(error: error)
        }        
    }
    
    //MARK: - User action
    
    @IBAction private func didSelectCheckButton(_ sender: Any) {
        let view: UIView = self.navigationController?.view ?? self.view
        STLoadingView.show(in: view)
        self.tableView.endEditing(true)
        self.viewModel.checkPhrase(email: self.emailTextField.text, phrase: self.phraseTextView.text) { [weak self] error in
            STLoadingView.hide(in: view)
            if let error = error {
                self?.showError(error: error)
            } else {
                self?.showResetPasswordAlert()
            }
        }
        
    }
        
}


extension STForgetPasswordVC: STTextViewDelegate {
    
    func textView(textView: STTextView, didChangeText: String?) {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
}

extension STForgetPasswordVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.confirmPasswordTextField {
            self.resetPassword(newPassword: self.newPasswordTextField?.text, confirmPassword: self.confirmPasswordTextField?.text)
            return false
        }
        return true
    }
    
}
