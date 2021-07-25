//
//  STSecurityVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

extension STSecurityVC {
    
    enum CellReusable: ISettingsItemReusableIdentifier {

        case detail
        case swich
        
        var nibName: String {
            switch self {
            case .detail:
                return "STSettingsDetailTableViewCell"
            case .swich:
                return "STSettingsSwichTableViewCell"
            }
        }
        
        var identifier: String {
            switch self {
            case .detail:
                return "detail"
            case .swich:
                return "swich"
            }
        }
        
    }
    
    enum HeaderReusable: ISettingsItemReusableIdentifier {

        case title
        
        var nibName: String {
            switch self {
            case .title:
                return "STSettingsHeaderView"
            }
        }
        
        var identifier: String {
            switch self {
            case .title:
                return "title"
            }
        }
        
    }
    
    struct Cell: ISettingsSectionCellItemModel {
        var reusableIdentifier: STSecurityVC.CellReusable
        var identifier: ItemType?
        var cellModel: ISettingsTableViewCellModel?
    }
    
    struct Header: ISettingsSectionHeaderItemModel {
        var reusableIdentifier: HeaderReusable
        var identifier: SectionType?
        var headerModel: STSettingsHeaderViewModel?
    }
    
    enum SectionType: String {
        
        case appAccess = "appAccess"
        case authentication = "authentication"
        case others = "others"
        
        var localized: String {
            switch self {
            case .appAccess:
                return "app_access".localized
            case .authentication:
                return "authentication".localized
            case .others:
                return "others".localized
            }
        }
    }
    
    
    enum ItemType {
        case lockUp
        case biometricAuthentication
        case requireConfirmation
        case disallowScreenshots
    }
    
    struct Section: ISettingsSection {
        var header: Header?
        var cells: [Cell]
    }
    
}

class STSecurityVC: STSettingsDetailVC<STSecurityVC.Section> {
        
    private var viewModel = STSecurityVM()
    
    private var security: STAppSettings.Security {
        return self.viewModel.security
    }
    
    override func configureLocalized() {
        self.navigationItem.title = "security".localized
        self.reloadTableData()
    }

    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath), let itemType = self.sections?[indexPath.section].cells[indexPath.row].identifier else {
            return
        }
                
        switch itemType {
        case .lockUp:
            self.showLockUpAppSheet(in: cell as! STSettingsDetailTableViewCell)
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let identifier = self.sections?[indexPath.section].cells[indexPath.row].reusableIdentifier
        return identifier == .detail
    }
    
    override func securityCel(didSelectSwich cell: ISettingsTableViewCell, model: ISettingsTableViewCellModel, isOn: Bool) {
        
        guard let indexPath = self.tableView.indexPath(for: cell), let identifier = self.cellModel(for: indexPath)?.identifier else {
            return
        }

        switch identifier {
        case .lockUp:
            return
        case .biometricAuthentication:
            if isOn {
                self.addBiometricAuth()
            } else {
                var touchId = (model as! STSettingsSwichTableViewCell.Model)
                touchId.isOn = isOn
                self.update(cellModel: touchId, for: indexPath)
                self.viewModel.removeBiometricAuthentication()
            }
        case .requireConfirmation:
            var swich = (model as! STSettingsSwichTableViewCell.Model)
            swich.isOn = isOn
            self.update(cellModel: swich, for: indexPath)
            self.viewModel.update(requireConfirmation: isOn)
        case .disallowScreenshots:
            var swich = (model as! STSettingsSwichTableViewCell.Model)
            swich.isOn = isOn
            self.update(cellModel: swich, for: indexPath)
            self.viewModel.update(disallowScreenshots: isOn)
        }
    }
    
    //MARK: - Private methods
    
    private func reloadTableDataModels() {
        let authentication = self.generateAuthenticationSection()
        let appAccess = self.generateAppAccessSection()
        let others = self.generateOthersSection()
        let sections = [authentication, appAccess, others]
        self.reloadTable(sections: sections)
    }
    
    private func reloadTableData() {
        self.reloadTableDataModels()
        self.tableView.reloadData()
    }
    
    private func generateAuthenticationSection() -> Section {
        let lockUp = STSettingsDetailTableViewCell.Model(itemType: .lockUp, image: UIImage(named: "ic_timer")!, title: "lock_up_the_app_after".localized, subTitle: self.security.lockUpApp.stringValue.localized)
        let cell = Cell(reusableIdentifier: .detail, identifier: .lockUp, cellModel: lockUp)
        
        let title = STSettingsHeaderViewModel(title: SectionType.appAccess.localized)
        let header = Header(reusableIdentifier: .title, identifier: .appAccess, headerModel: title)
        return Section(header: header, cells: [cell])
    }
    
    private func generateAppAccessSection() -> Section {
        
        let hasBiometric = self.viewModel.biometric.state != .notAvailable
        let hasBiometricAuthInApp = hasBiometric && self.viewModel.biometric.canUnlockApp
        
        let imageName = self.viewModel.biometric.type == .faceID ? "ic_face_id" : "ic_touch_id"
        let touchId = STSettingsSwichTableViewCell.Model(itemType: .biometricAuthentication, image: UIImage(named: imageName)!, title: "biometric_authentication".localized, subTitle: "biometric_authentication_message".localized, isOn: self.security.authentication.unlock && hasBiometricAuthInApp, isEnabled: hasBiometric)
        
        let touchIdCell = Cell(reusableIdentifier: .swich, identifier: .biometricAuthentication, cellModel: touchId)
        
        
        let confirmation = STSettingsSwichTableViewCell.Model(itemType: .requireConfirmation, image: UIImage(named: "ic_mark")!, title: "require_confirmation".localized, subTitle: "require_confirmation_message".localized, isOn: self.security.authentication.requireConfirmation && hasBiometricAuthInApp, isEnabled: hasBiometric)
        
        let confirmationCell = Cell(reusableIdentifier: .swich, identifier: .requireConfirmation, cellModel: confirmation)
        
        let title = STSettingsHeaderViewModel(title: SectionType.authentication.localized)
        let header = Header(reusableIdentifier: .title, identifier: .authentication, headerModel: title)
        return Section(header: header, cells: [touchIdCell, confirmationCell])
        
    }
    
    private func generateOthersSection() -> Section {
        let screenshot = STSettingsSwichTableViewCell.Model(itemType: .disallowScreenshots, image: UIImage(named: "ic_lock")!, title: "disallow_screenshots_off_this_app".localized, subTitle: nil, isOn: self.security.disallowScreenshots, isEnabled: true)
        
        let screenshotCell = Cell(reusableIdentifier: .swich, identifier: .disallowScreenshots, cellModel: screenshot)
        
        let title = STSettingsHeaderViewModel(title: SectionType.others.localized)
        let header = Header(reusableIdentifier: .title, identifier: .others, headerModel: title)
        return Section(header: header, cells: [screenshotCell])
    }
    
    private func showLockUpAppSheet(in cell: STSettingsDetailTableViewCell) {
        let alert = UIAlertController(title: "lock_up_the_app_after".localized, message: nil, preferredStyle: .actionSheet)
        STAppSettings.Security.LockUpApp.allCases.forEach { lockUpApp in
            let action = UIAlertAction(title: lockUpApp.stringValue, style: .default) { [weak self] _ in
                self?.viewModel.update(lockUpApp: lockUpApp)
                cell.update(subTitle: lockUpApp.stringValue)
            }
            alert.addAction(action)
        }
        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(cancel)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = cell
        }
        self.showDetailViewController(alert, sender: nil)
    }
    
    private func addBiometricAuth(password: String?) {
        guard let password = password, !password.isEmpty else {
            self.showOkCancelAlert(title: "warning".localized, message: "error_password_not_valed".localized)
            return
        }
        let loadingView: UIView =  self.navigationController?.view ?? self.view
        STLoadingView.show(in: loadingView)
        self.viewModel.add(biometricAuthentication: password) { [weak self] error in
            if let error = error {
                self?.showError(error: error)
                self?.reloadTableData()
            } else {
                self?.reloadTableDataModels()
            }
            STLoadingView.hide(in: loadingView)
        }
    }
    
    private func addBiometricAuth() {
        let title = "enter_app_password".localized
        self.showOkCancelAlert(title: title, message: nil) { textField in
            textField.placeholder = "password".localized
            textField.isSecureTextEntry = true
        } handler: { [weak self] text in
            self?.addBiometricAuth(password: text)
        } cancel: { [weak self] in
            self?.reloadTableData()
        }
    }
    
}
