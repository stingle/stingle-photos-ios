//
//  STChangePasswordVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/29/21.
//

import UIKit

class STChangePasswordVC: UITableViewController {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var passwordTextField: UITextField!
    @IBOutlet weak private var newPasswordTextField: UITextField!
    @IBOutlet weak private var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak private var changePasswordButton: UIButton!
    @IBOutlet weak private var cancelButton: UIButton!
    
    private var viewModel = STChangePasswordVM()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureLocalized()
    }
    
    //MARK: - Override methods
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    //MARK: - Private methods
    
    private func configureLocalized() {
        self.passwordTextField.placeholder = "password".localized
        self.newPasswordTextField.placeholder = "new_password".localized
        self.confirmPasswordTextField.placeholder = "new_password".localized
        self.titleLabel.text = "reset_password_title".localized
        self.navigationItem.title = "change_password".localized
        self.changePasswordButton.setTitle("change".localized.uppercased(), for: .normal)
        self.cancelButton.setTitle("cancel".localized.uppercased(), for: .normal)
    }
    
    //MARK: - User action
    
    @IBAction private func didSelectChangePasswordButton(_ sender: UIButton) {
        
        let oldPassword = self.passwordTextField.text
        let newPassword = self.newPasswordTextField.text
        let confirmPassword = self.confirmPasswordTextField.text
        self.tableView.endEditing(true)
        
        let view: UIView = self.navigationController?.view ?? self.view
        STLoadingView.show(in: view)
        
        self.viewModel.changePassword(oldPassword: oldPassword, newPassword: newPassword, confirmPassword: confirmPassword) { [weak self] error in
            if let error = error {
                self?.showError(error: error)
            } else {
                self?.navigationController?.popViewController(animated: true)
            }
            STLoadingView.hide(in: view)
        }
        
    }
    
    @IBAction private func didSelectCancelButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
