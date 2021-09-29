//
//  STAppearanceVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

class STAppearanceVC: STSettingsDetailTableVC<STAppearanceVC.SectionType, STAppearanceVC.ItemType> {
    
    typealias Section = STSettingsDetailTableInfo.Section<STAppearanceVC.SectionType, STAppearanceVC.ItemType>
    typealias CellModel = Section.Cell
    typealias HeaderModel = Section.Header
    
    private let viewModel = STAppearanceVM()
    
    private var appearance: STAppSettings.Appearance {
        return self.viewModel.appearance
    }
    
    override func configureLocalized() {
        self.navigationItem.title = "appearance".localized
        self.reloadTableData()
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let identifier = self.sections?[indexPath.section].cells[indexPath.row].reusableIdentifier
        return identifier == .detail
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath), let itemType = self.sections?[indexPath.section].cells[indexPath.row].identifier else {
            return
        }
        
        switch itemType {
        case .theme:
            guard let detailCell = cell as? STSettingsDetailTableViewCell else {
                return
            }
            self.showThemeAppSheet(in: detailCell)
        }
    }
    
    //MARK: - Private methods
    
    private func update(in cell: STSettingsDetailTableViewCell, theme: STAppSettings.Appearance.Theme) {
        self.viewModel.updateTheme(theme: theme)
        cell.update(subTitle: theme.localized)
        guard let indexPath = self.tableView.indexPath(for: cell), let cellModel = cell.cellModel else {
            return
        }
        self.update(cellModel: cellModel, for: indexPath)
    }
    
    private func showThemeAppSheet(in cell: STSettingsDetailTableViewCell) {
        let alert = UIAlertController(title: "theme".localized, message: nil, preferredStyle: .actionSheet)
        
        STAppSettings.Appearance.Theme.allCases.forEach { theme in
            let action = UIAlertAction(title: theme.localized, style: .default) { [weak self] _ in
                self?.update(in: cell, theme: theme)
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
    
    private func reloadTableData() {
        self.reloadTableDataModels()
        self.tableView.reloadData()
    }
    
    private func reloadTableDataModels() {
        let sections = self.generateSections()
        self.reloadTable(sections: sections)
    }
    
    private func generateSections() -> [Section] {
        let themeCellModel = STSettingsDetailTableViewCell.Model(image: UIImage(named: "ic_settings_appearance")!, title: "theme".localized, subTitle: self.appearance.theme.localized)
        let theme = CellModel(reusableIdentifier: .detail, identifier: .theme, cellModel: themeCellModel)
        let cells: [CellModel] = [theme]
        let section = Section(identifier: nil, header: nil, cells: cells)
        return [section]
    }

}

extension STAppearanceVC {
    
    enum SectionType {
    }
    
    enum ItemType: Int {
        case theme = 0
    }

}
