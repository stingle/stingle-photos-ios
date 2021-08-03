//
//  STBackupVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

class STBackupVC: STSettingsDetailTableVC<STBackupVC.SectionType, STBackupVC.ItemType> {
    
    typealias Section = STSettingsDetailTableInfo.Section<STBackupVC.SectionType, STBackupVC.ItemType>
    typealias CellModel = Section.Cell
    typealias HeaderModel = Section.Header
        
    private let viewModel = STBackupVM()
    
    private var backup: STAppSettings.Backup {
        return self.viewModel.backup
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureLocalized() {
        self.navigationItem.title = "backup".localized
        self.reloadTableData()
    }
    
    override func securityCel(didSlide cell: ISettingsTableViewCell, model: ISettingsTableViewCellModel, value: Float) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        let subTitle = "\(Int(value * 100))%"
        (cell as? STSettingsSliderTableViewCell)?.updateSubTitle(subTitle)
        let model = (cell as? STSettingsSliderTableViewCell)?.cellModel ?? model
        self.update(cellModel: model, for: indexPath)
        
        guard let cellModel = self.cellModel(for: indexPath) else {
            return
        }
        
        switch cellModel.identifier {
        case .battery:
            self.viewModel.updateBackup(batteryLevel: value)
        default:
            break
        }
    }
    
    override func securityCel(didSelectSwich cell: ISettingsTableViewCell, model: ISettingsTableViewCellModel, isOn: Bool) {
        guard let indexPath = self.tableView.indexPath(for: cell), var cellModel = (cell as? STSettingsSwichTableViewCell)?.cellModel else {
            return
        }
        
        cellModel.isOn = isOn
        self.update(cellModel: cellModel, for: indexPath)
                
        guard let identifier = self.cellModel(for: indexPath)?.identifier else {
            return
        }
        switch identifier {
        case .enableBackup:
            self.viewModel.updateBackup(isEnabled: isOn)
            let sections = self.generateSections()
            self.reloadVisibleCells(sections: sections)
        case .onlyWiFi:
            self.viewModel.updateBackup(isOnlyWiFi: isOn)
        case .battery:
            break
        }
    }
    
    //MARK: - Private
    
    private func reloadTableData() {
        self.reloadTableDataModels()
        self.tableView.reloadData()
    }
    
    private func reloadTableDataModels() {
        let sections = self.generateSections()
        self.reloadTable(sections: sections)
    }
    
    private func generateSections() -> [Section] {
        let enableBackupCellModel = STSettingsSwichTableViewCell.Model(image: UIImage(named: "ic_settings_backup")!, title: "enable_backup".localized, subTitle: "enable_backup_description".localized, isOn: self.backup.isEnabled, isEnabled: true)
        let enableBackup = CellModel(reusableIdentifier: .swich, identifier: .enableBackup, cellModel: enableBackupCellModel)
        
        let enableBackupWifiCellModel = STSettingsSwichTableViewCell.Model(image: UIImage(named: "ic_settings_wifi")!, title: "backup_only_wifi".localized, subTitle: "backup_only_wifi_description".localized, isOn: self.backup.isOnlyWiFi, isEnabled: self.backup.isEnabled)
        let enableBackupWiFi = CellModel(reusableIdentifier: .swich, identifier: .onlyWiFi, cellModel: enableBackupWifiCellModel)
                
        let battaryCellModel = STSettingsSliderTableViewCell.Model(image: UIImage(named: "ic_settings_battary")!, title: "backup_battery".localized, subTitle: "\(Int(self.backup.batteryLevel * 100))%", value: self.backup.batteryLevel, isEnabled: self.backup.isEnabled)
        let battary = CellModel(reusableIdentifier: .slider, identifier: .battery, cellModel: battaryCellModel)
        
        let cells: [CellModel] = [enableBackup, enableBackupWiFi, battary]
        let section = Section(identifier: nil, header: nil, cells: cells)
        return [section]
    }
    
}

extension STBackupVC {
    
    enum SectionType {
    }
    
    enum ItemType: Int {
        case enableBackup = 0
        case onlyWiFi = 1
        case battery = 2
    }

}
