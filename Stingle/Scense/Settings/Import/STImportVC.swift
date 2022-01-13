//
//  STImportVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

class STImportVC: STSettingsDetailTableVC<STImportVC.SectionType, STImportVC.ItemType> {
        
    typealias Section = STSettingsDetailTableInfo.Section<STImportVC.SectionType, STImportVC.ItemType>
    typealias CellModel = Section.Cell
    typealias HeaderModel = Section.Header
    
    private let viewModel = ViewModel()
    
    private var `import`: STAppSettings.Import {
        return self.viewModel.import
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadTableData()
    }

    override func configureLocalized() {
        self.navigationItem.title = "import".localized
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard (self.cellModel(for: indexPath)?.cellModel)?.isEnabled == true else {
            return false
        }
        let identifier = self.sections?[indexPath.section].cells[indexPath.row].reusableIdentifier
        return identifier == .detail
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath), let itemType = self.sections?[indexPath.section].cells[indexPath.row].identifier else {
            return
        }

        switch itemType {
        case .manualImportDeleteFiles:
            guard let detailCell = cell as? STSettingsDetailTableViewCell else {
                return
            }
            self.showManualImport(in: detailCell)
        case .autoImportiExistingFiles:
            self.showImportManualImportAlert()
        default:
            break
        }
    }
    
    override func settingsyCel(didSelectSwich cell: ISettingsTableViewCell, model: ISettingsTableViewCellModel, isOn: Bool) {
        
        super.settingsyCel(didSelectSwich: cell, model: model, isOn: isOn)
        guard let indexPath = self.tableView.indexPath(for: cell), let identifier = self.cellModel(for: indexPath)?.identifier else {
            return
        }
        
        switch identifier {
        case .autoImportEnable:
            self.viewModel.update(autoImportEnable: isOn) { [weak self] error in
                self?.show(error: error, actionHandler: { [weak self] in
                    self?.updateVisibleCells()
                })
            }
        case .autoImportDeleteFiles:
            self.viewModel.update(autoImportDeleteFiles: isOn) { [weak self] error in
                self?.show(error: error, actionHandler: { [weak self] in
                    self?.updateVisibleCells()
                })
            }
        case .autoImportiExistingFiles:
            break
        case .manualImportDeleteFiles:
            return
        
            
        }
    }
    
    //MARK: - Private methods
    
    private func updateVisibleCells() {
        let sections = self.generateSections()
        self.reloadVisibleCells(sections: sections)
    }
    
    private func show(error: ImportError?, actionHandler: (() -> Void)?) {
        
        guard let error = error else {
            actionHandler?()
            return
        }
        
        switch error {
        case .phAuthorizationStatus:
            let okAction: (title: String, handler: (() -> Void)?) = ("settings".localized, {
                actionHandler?()
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) else {
                    return
                }
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            })
            
            let cancelAction: (title: String, handler: (() -> Void)?) = (title: "cancel".localized, handler: {
                actionHandler?()
            })
            self.showOkCancelAlert(title: "warning".localized, message: error.message, ok: okAction, cancel: cancelAction)
        }
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
        let autoImport = self.generateAutoImportSection()
        let manualImport = self.generateManualImportSection()
        return [autoImport, manualImport]
    }
    
    private func generateAutoImportSection() -> Section {
        
        let header = HeaderModel(reusableIdentifier: .title, identifier: .autoImport, headerModel: STSettingsHeaderViewModel(title: "auto_import_settings".localized))
        
        let enableImportImage = UIImage(named: "ic_settings_import")!
        let enableImport = STSettingsSwichTableViewCell.Model(image: enableImportImage, title: "enable_auto_import".localized, subTitle: "enable_auto_import_description".localized, isOn: self.import.isAutoImportEnable, isEnabled: true)
        let enableImportCell = CellModel(reusableIdentifier: .swich, identifier: .autoImportEnable, cellModel: enableImport)

        let deleteOriginalFilesImage = UIImage(named: "ic_trash")!
        let deleteOriginal = STSettingsSwichTableViewCell.Model(image: deleteOriginalFilesImage, title: "delete_original_files_after_import".localized, subTitle: "delete_original_files_after_import_description".localized, isOn: self.import.isDeleteOriginalFilesAfterAutoImport, isEnabled: self.import.isAutoImportEnable)
        let deleteOriginalCell = CellModel(reusableIdentifier: .swich, identifier: .autoImportDeleteFiles, cellModel: deleteOriginal)
        
        let importExistPhotosImage = UIImage(named: "ic_settings_import_exist")!
        let importExistPhotos = STSettingsDetailTableViewCell.Model(image: importExistPhotosImage, title: "import_existing_photos_and_videos".localized, subTitle: nil, isEnabled: self.import.isAutoImportEnable)
        let importExistPhotosCell = CellModel(reusableIdentifier: .detail, identifier: .autoImportiExistingFiles, cellModel: importExistPhotos)
        
        let section = Section(identifier: .autoImport, header: header, cells: [enableImportCell, deleteOriginalCell, importExistPhotosCell])
        return section
        
    }
    
    private func generateManualImportSection() -> Section {
        let header = HeaderModel(reusableIdentifier: .title, identifier: .autoImport, headerModel: STSettingsHeaderViewModel(title: "manual_import".localized))
        
        let deleteOriginalFilesImage = UIImage(named: "ic_trash")!
        let deleteOriginal = STSettingsDetailTableViewCell.Model(image: deleteOriginalFilesImage, title: "manual_import_title".localized, subTitle: self.import.manualImportDeleteFilesType.localized, isEnabled: true)
        let deleteOriginalCell = CellModel(reusableIdentifier: .detail, identifier: .manualImportDeleteFiles, cellModel: deleteOriginal)
        
        let section = Section(identifier: .manualImport, header: header, cells: [deleteOriginalCell])
        return section
    }
    
    private func showManualImport(in cell: STSettingsDetailTableViewCell) {
        let alert = UIAlertController(title: nil, message: "manual_import_title".localized, preferredStyle: .actionSheet)
        STAppSettings.Import.ManualImportDeleteFilesType.allCases.forEach { type in
            let action = UIAlertAction(title: type.localized, style: .default) { [weak self] _ in
                self?.viewModel.update(manualImportDeleteFilesType: type) { [weak self] error in
                    self?.show(error: error, actionHandler: { [weak self] in
                        self?.updateVisibleCells()
                    })
                }
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
    
    private func showImportManualImportAlert() {
        
        let ok = {
            print("okokok")
        }
        
        self.showOkCancelAlert(title: "import".localized, message: "import_existing_files_alert_message".localized, ok: ("ok".localized, ok))
        
    }

}

extension STImportVC {
    
    enum SectionType {
        case autoImport
        case manualImport
    }
    
    enum ItemType: Int {
        case autoImportEnable = 0
        case autoImportDeleteFiles = 1
        case autoImportiExistingFiles = 2
        case manualImportDeleteFiles = 3
    }

}
