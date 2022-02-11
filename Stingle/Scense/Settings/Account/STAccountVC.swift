//
//  STAccountVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

class STAccountVC: STSettingsDetailTableVC<STAccountVC.SectionType, STAccountVC.ItemType> {
    
    typealias Section = STSettingsDetailTableInfo.Section<STAccountVC.SectionType, STAccountVC.ItemType>
    typealias CellModel = Section.Cell
    typealias HeaderModel = Section.Header
    
    private let viewModel = STAccountVM()

    //MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureLocalized() {
        self.navigationItem.title = "account".localized
        self.reloadTableData()
    }
    
    override func settingsyCel(didSelectSwich cell: ISettingsTableViewCell, model: ISettingsTableViewCellModel, isOn: Bool) {
        super.settingsyCel(didSelectSwich: cell, model: model, isOn: isOn)
        guard let indexPath = self.tableView.indexPath(for: cell), let identifier = self.cellModel(for: indexPath)?.identifier else {
            return
        }
        switch identifier {
        case .backcupKeys:
            if isOn {
                self.addBackcupKeys()
            } else {
                self.removeBackcupKeys()
            }
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let identifier = self.cellModel(for: indexPath)?.identifier else {
            return false
        }
        return identifier == .changePassword || identifier == .deleteAccount
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let identifier = self.cellModel(for: indexPath)?.identifier else {
            return
        }
        
        switch identifier {
        case .changePassword:
            let storyboard = UIStoryboard(name: "Welcome", bundle: .main)
            let vc = storyboard.instantiateViewController(identifier: "STChangePasswordVCID")
            self.show(vc, sender: nil)
        case .deleteAccount:
            let title = "delete_account_alert_title".localized
            let message = "delete_account_alert_message".localized
            self.showOkCancelTextAlert(title: title, message: message, handler: { [weak self] _ in
                self?.deleteAccount()
            })
            
            break
        default:
            break
        }
    }
    
    //MARK: - Private
    
    private func reloadTableData() {
        self.reloadTableDataModels()
        self.tableView.reloadData()
    }
    
    private func removeBackcupKeys() {
        let title = "remove_backcup_keys_alert_title".localized
        let message = "remove_backcup_keys_alert_message".localized
        let loadingView: UIView =  self.navigationController?.view ?? self.view
        self.showOkCancelTextAlert(title: title, message: message, textFieldHandler: nil) { [weak self] _ in
            STLoadingView.show(in: loadingView)
            self?.viewModel.removeBackcupKeys(completion: { error in
                if let error = error {
                    self?.showError(error: error)
                }
                self?.reloadTableData()
                STLoadingView.hide(in: loadingView)
            })
        } cancel: { [weak self]  in
            self?.reloadTableData()
        }
    }
    
    private func addBackcupKeys(password: String?) {
        guard let password = password, !password.isEmpty else {
            self.showOkCancelTextAlert(title: "warning".localized, message: "error_password_not_valed".localized)
            return
        }
        let loadingView: UIView =  self.navigationController?.view ?? self.view
        STLoadingView.show(in: loadingView)
        self.viewModel.addBackcupKeys(password: password) { [weak self] error in
            STLoadingView.hide(in: loadingView)
            if let error = error {
                self?.showError(error: error)
            }
            self?.reloadTableData()
        }
    }
    
    private func addBackcupKeys() {
        let title = "enter_app_password".localized
        self.showOkCancelTextAlert(title: title, message: nil) { textField in
            textField.placeholder = "password".localized
            textField.isSecureTextEntry = true
        } handler: { [weak self] text in
            self?.addBackcupKeys(password: text)
        } cancel: { [weak self] in
            self?.reloadTableData()
        }
    }

    private func reloadTableDataModels() {
        
        guard let user = self.viewModel.getUser() else {
            return
        }
        
        let emailCellModel = STSettingsDetailTableViewCell.Model(image: UIImage(named: "ic_settings_account")!, title: "email".localized, subTitle: user.email, isEnabled: false)
        let email = CellModel(reusableIdentifier: .detail, identifier: .userMail, cellModel: emailCellModel)
        
        let changePasswordCellModel = STSettingsDetailTableViewCell.Model(image: UIImage(named: "ic_settings_key")!, title: "change_password".localized, subTitle: nil)
        let changePassword = CellModel(reusableIdentifier: .detail, identifier: .changePassword, cellModel: changePasswordCellModel)
        
        let backupCellModel = STSettingsSwichTableViewCell.Model(image: UIImage(named: "ic_settings_backup")!, title: "backup_my_keys".localized, subTitle: "backup_my_keys_description".localized, isOn: user.isKeyBackedUp, isEnabled: true)
        let backup = CellModel(reusableIdentifier: .swich, identifier: .backcupKeys, cellModel: backupCellModel)
        
        let deleteAccountCellModel = STSettingsDetailTableViewCell.Model(image: UIImage(named: "ic_menu_trash")!, title: "delete_account".localized, subTitle: nil)
        let deleteAccount = CellModel(reusableIdentifier: .detail, identifier: .deleteAccount, cellModel: deleteAccountCellModel)
                
        let cells: [CellModel] = [email, changePassword, backup, deleteAccount]
        let section = Section(identifier: nil, header: nil, cells: cells)
        
        self.reloadTable(sections: [section])
    }
    
    
    private func deleteAccount(password: String) {
        let loadingView: UIView =  self.navigationController?.view ?? self.view
        STLoadingView.show(in: loadingView)
        self.viewModel.deleteAccount(password: password) { [weak self] error in
            STLoadingView.hide(in: loadingView)
            if let error = error {
                self?.showError(error: error)
            }
        }
    }
    
    private func deleteAccount(password: String?) {
        
        guard let password = password, !password.isEmpty else {
            self.showOkCancelTextAlert(title: "warning".localized, message: "error_password_not_valed".localized)
            return
        }
        
        self.viewModel.validatePassword(password) { [weak self] error in
            if let error = error {
                self?.showError(error: error)
            } else {
                let title = "delete_account_seccoundry_alert_title".localized
                let message = "delete_account_seccoundry_alert_message".localized
                self?.showOkCancelTextAlert(title: title, message: message, textFieldHandler: nil, handler: { _ in
                    self?.deleteAccount(password: password)
                }, cancel: nil)
            }
        }
    }
    
    private func deleteAccount() {
        let title = "enter_app_password".localized
        self.showOkCancelTextAlert(title: title, message: nil, textFieldHandler: { textField in
            textField.placeholder = "password".localized
            textField.isSecureTextEntry = true
        }, handler: { [weak self] text in
            self?.deleteAccount(password: text)
        }, cancel: nil)
    }
        
}

extension STAccountVC {
    
    enum SectionType {
    }
    
    enum ItemType: Int {
        case userMail = 0
        case changePassword = 1
        case backcupKeys = 2
        case deleteAccount = 3
    }

}
