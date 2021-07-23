//
//  STSecurityVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

class STSecurityVC: UIViewController {
    
    @IBOutlet weak private var tableView: UITableView!
    
    private var sections = [Section]()
    private var viewModel = STSecurityVM()
    private let headerViewIdentifier = "STSecurityHeaderView"
    
    private var security: STAppSettings.Security {
        return self.viewModel.security
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerTableView()
        self.configureLocalizes()
    }
    
    //MARK: - Private methods
    
    private func registerTableView() {
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedSectionHeaderHeight = 44
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        CellType.allCases.forEach { typr in
            self.tableView.register(UINib(nibName: typr.nibName, bundle: .main), forCellReuseIdentifier: typr.reusableIdentifier)
        }
        self.tableView.register(UINib(nibName: "STSecurityHeaderView", bundle: .main), forHeaderFooterViewReuseIdentifier: self.headerViewIdentifier)
    }
    
    private func configureLocalizes() {
        self.navigationItem.title = "security".localized
        self.reloadTableData()
    }
    
    private func reloadTableDataModels() {
        let authentication = self.generateAuthenticationSection()
        let appAccess = self.generateAppAccessSection()
        let others = self.generateOthersSection()
        self.sections = [authentication, appAccess, others]
    }
    
    private func reloadTableData() {
        self.reloadTableDataModels()
        self.tableView.reloadData()
    }
    
    private func generateAuthenticationSection() -> Section {
        let lockUp = STSecurityDetailTableViewCell.Model(itemType: .lockUp, image: UIImage(named: "ic_timer")!, title: "lock_up_the_app_after".localized, subTitle: self.security.lockUpApp.stringValue.localized)
        return Section(sectionType: .appAccess, items: [lockUp])
    }
    
    private func generateAppAccessSection() -> Section {
        
        let hasBiometric = self.viewModel.biometric.state != .notAvailable
        let hasBiometricAuthInApp = hasBiometric && self.viewModel.biometric.canUnlockApp
        
        let imageName = self.viewModel.biometric.type == .faceID ? "ic_face_id" : "ic_touch_id"
        let touchId = STSecuritySwichTableViewCell.Model(itemType: .biometricAuthentication, image: UIImage(named: imageName)!, title: "biometric_authentication".localized, subTitle: "biometric_authentication_message".localized, isOn: self.security.authentication.unlock && hasBiometricAuthInApp, isEnabled: hasBiometric)
        
        let confirmation = STSecuritySwichTableViewCell.Model(itemType: .requireConfirmation, image: UIImage(named: "ic_mark")!, title: "require_confirmation".localized, subTitle: "require_confirmation_message".localized, isOn: self.security.authentication.requireConfirmation && hasBiometricAuthInApp, isEnabled: hasBiometric)
        
        let section = Section(sectionType: .authentication, items: [touchId, confirmation])
        return section
    }
    
    private func generateOthersSection() -> Section {
        let screenshot = STSecuritySwichTableViewCell.Model(itemType: .disallowScreenshots, image: UIImage(named: "ic_lock")!, title: "disallow_screenshots_off_this_app".localized, subTitle: nil, isOn: self.security.disallowScreenshots, isEnabled: true)
        let section = Section(sectionType: .others, items: [screenshot])
        return section
    }
    
    private func showLockUpAppSheet(in cell: STSecurityDetailTableViewCell) {
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

extension STSecurityVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = self.sections[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellModel.itemType.cellType.reusableIdentifier, for: indexPath)
        let security = (cell as? ISecurityVCTableViewCell)
        security?.configure(model: cellModel)
        security?.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

extension STSecurityVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = self.sections[section]
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.headerViewIdentifier)
        (header as? STSecurityHeaderView)?.configure(title: section.sectionType.localized)
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        let itemType = self.sections[indexPath.section].items[indexPath.row].itemType
        switch itemType {
        case .lockUp:
            self.showLockUpAppSheet(in: cell as! STSecurityDetailTableViewCell)
        default:
            break
        }        
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let cellModel = self.sections[indexPath.section].items[indexPath.row]
        return cellModel.itemType.cellType == .detail
    }
    
}

extension STSecurityVC: STSecurityVCTableViewCellDelegate {
    
    func securityCel(didSelectSwich cell: ISecurityVCTableViewCell, model: ISecurityTableViewCellModel, isOn: Bool) {
        
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
                
        switch model.itemType {
        case .lockUp:
            return
        case .biometricAuthentication:
            if isOn {
                self.addBiometricAuth()
            } else {
                var touchId = (model as! STSecuritySwichTableViewCell.Model)
                touchId.isOn = isOn
                self.sections[indexPath.section].items[indexPath.row] = touchId
                self.viewModel.removeBiometricAuthentication()
            }
        case .requireConfirmation:
            var touchId = (model as! STSecuritySwichTableViewCell.Model)
            touchId.isOn = isOn
            self.sections[indexPath.section].items[indexPath.row] = touchId
            self.viewModel.update(requireConfirmation: isOn)
        case .disallowScreenshots:
            var touchId = (model as! STSecuritySwichTableViewCell.Model)
            touchId.isOn = isOn
            self.sections[indexPath.section].items[indexPath.row] = touchId
            self.viewModel.update(disallowScreenshots: isOn)
        }
    }
    
}

extension STSecurityVC {
    
    struct Section {
        let sectionType: SectionType
        var items: [ISecurityTableViewCellModel]
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
    
    enum CellType: CaseIterable {
        
        case detail
        case swich
        
        var nibName: String {
            switch self {
            case .detail:
                return "STSecurityDetailTableViewCell"
            case .swich:
                return "STSecuritySwichTableViewCell"
            }
        }
        
        var reusableIdentifier: String {
            switch self {
            case .detail:
                return "detail"
            case .swich:
                return "swich"
            }
        }
        
    }
    
    enum ItemType {
        
        case lockUp
        case biometricAuthentication
        case requireConfirmation
        case disallowScreenshots
        
        var cellType: CellType {
            switch self {
            case .lockUp:
                return .detail
            case .biometricAuthentication, .requireConfirmation, .disallowScreenshots:
                return .swich
            }
        }
                        
    }
    
}
