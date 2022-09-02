//
//  STAdvancedVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit
import StingleRoot

class STAdvancedVC: STSettingsDetailTableVC<STAdvancedVC.SectionType, STAdvancedVC.ItemType> {
    
    typealias Section = STSettingsDetailTableInfo.Section<STAdvancedVC.SectionType, STAdvancedVC.ItemType>
    typealias CellModel = Section.Cell
    typealias HeaderModel = Section.Header
        
    private let viewModel = STAdvancedVM()
    
    private var appearance: STAppSettings.Advanced {
        return self.viewModel.advanced
    }
    
    //MARK: - Override methods

    override func configureLocalized() {
        self.navigationItem.title = "advanced".localized
        self.reloadTableData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath), let itemType = self.sections?[indexPath.section].cells[indexPath.row].identifier else {
            return
        }
        
        switch itemType {
        case .cacheSize:
            guard let detailCell = cell as? STSettingsDetailTableViewCell else {
                return
            }
            self.showCacheSizeSheet(in: detailCell)
        case .deleteCache:
            self.deleteCache()
        }
    }
    
    //MARK: - Private methods
    
    private func reloadTableData() {
        self.reloadTableDataModels()
        self.tableView.reloadData()
    }
    
    private func reloadTableDataModels() {
        let sections = self.generateSections()
        self.reloadTable(sections: sections)
    }
    
    private func generateSections() -> [Section] {
        let cacheSizeModel = STSettingsDetailTableViewCell.Model(image: UIImage(named: "ic_settings_cache_size")!, title: "max_cache_size".localized, subTitle: self.appearance.cacheSize.localized)
        let cacheSize = CellModel(reusableIdentifier: .detail, identifier: .cacheSize, cellModel: cacheSizeModel)
                
        let deleteCacheModel = STSettingsDetailTableViewCell.Model(image: UIImage(named: "ic_menu_trash")!, title: "delete_cache".localized, subTitle: "delete_cache_description".localized)
        let deleteCache = CellModel(reusableIdentifier: .detail, identifier: .deleteCache, cellModel: deleteCacheModel)
        
        let cells: [CellModel] = [cacheSize, deleteCache]
        let section = Section(identifier: nil, header: nil, cells: cells)
        return [section]
    }
    
    
    private func showCacheSizeSheet(in cell: STSettingsDetailTableViewCell) {
        let alert = UIAlertController(title: "max_cache_size".localized, message: nil, preferredStyle: .actionSheet)
        
        STAppSettings.Advanced.CacheSize.allCases.forEach { theme in
            let action = UIAlertAction(title: theme.localized, style: .default) { [weak self] _ in
                self?.update(in: cell, cacheSize: theme)
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
    
    private func update(in cell: STSettingsDetailTableViewCell, cacheSize: STAppSettings.Advanced.CacheSize) {
        self.viewModel.update(cacheSize: cacheSize)
        cell.update(subTitle: cacheSize.localized)
        guard let indexPath = self.tableView.indexPath(for: cell), let cellModel = cell.cellModel else {
            return
        }
        self.update(cellModel: cellModel, for: indexPath)
    }
    
    private func deleteCache() {
        let title = "delete?".localized
        let message = "delete_cache_alert_message".localized
        self.showInfoAlert(title: title, message: message, cancel: true) { [weak self] in
            self?.viewModel.removeCache()
        }
    }

}

extension STAdvancedVC {
    
    enum SectionType {
    }
    
    enum ItemType: Int {
        case cacheSize = 0
        case deleteCache = 1
    }

}
