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

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureLocalized() {
        self.navigationItem.title = "account".localized
        self.reloadTableData()
    }
    
    //MARK: - Private
    
    private func reloadTableData() {
        self.reloadTableDataModels()
        self.tableView.reloadData()
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
    
}

extension STAccountVC {
    
    enum SectionType {
    }
    
    enum ItemType {
        case userMail
        case changePassword
        case backcupKeys
        case deleteAccount
    }

}
