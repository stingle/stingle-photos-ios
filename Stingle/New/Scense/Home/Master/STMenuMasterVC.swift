//
//  STmenuMasterVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/5/21.
//

import UIKit

class STMenuMasterVC: UIViewController {
    
    private(set) var currentControllerType = ControllerType.gallery
    private let cellReuseIdentifier = "CellReuseIdentifier"
    private let headerViewReuseIdentifier = "HeaderViewReuseIdentifier"
    
    private var menu: Menu?
        
    @IBOutlet weak private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.registrTableView()
        self.menu = Menu.current()
        STApplication.shared.syncManager.addListener(self)
        self.tableView.selectRow(at: IndexPath(row: self.currentControllerType.rawValue, section: 0), animated: true, scrollPosition: .none)
        self.set(controllerType: self.currentControllerType)
        STApplication.shared.dataBase.dbInfoProvider.add(self)
    }
    
    //MARK: - Private
    
    private func reloadData() {
        self.menu = Menu.current()
        self.tableView.reloadData()
        self.selectCurrentRow()
    }
    
    private func selectCurrentRow() {
        self.tableView.selectRow(at: IndexPath(row: self.currentControllerType.rawValue, section: 0), animated: true, scrollPosition: .none)
    }
    
    private func registrTableView() {
        self.tableView.register(UINib(nibName: "STMenuMasterTableViewCell", bundle: .main), forCellReuseIdentifier: self.cellReuseIdentifier)
        self.tableView.register(UINib(nibName: "STMenuMasterHeaderView", bundle: .main), forHeaderFooterViewReuseIdentifier: self.headerViewReuseIdentifier)
    }
    
    private func set(controllerType: ControllerType) {
        let menuVC = self.splitMenuViewController as? STMenuVC
        menuVC?.setDetailViewController(identifier: controllerType.identifier)
        self.currentControllerType = controllerType
    }
    
}

extension STMenuMasterVC: UITableViewDataSource, UITableViewDelegate {

    //MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.headerViewReuseIdentifier) as? STMenuMasterHeaderView
        header?.configure(model: self.menu?.header)
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = self.menu?.cells[indexPath.row] else {
            return
        }
        switch item.controllerType {
        case .officialWebsite:
            if let url = URL(string: STEnvironment.current.appWebUrl), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            self.selectCurrentRow()
        case .signOut:
            let title = "alert_log_out_title".localized
            let message = "alert_log_out_message".localized
            self.showOkCancelAlert(title: title, message: message, textFieldHandler: nil, handler: { _ in
                STApplication.shared.logout()
            }, cancel: nil)
            self.selectCurrentRow()
        case .lockApp:
            self.splitMenuViewController?.closeMenu()
            STApplication.shared.appLocker.lockApp()
        case .freeUpSpace:
            STApplication.shared.fileSystem.freeUpSpace()
            let title = "alert_free_up_space_title".localized
            let message = "alert_free_up_space_message".localized
            self.showInfoAlert(title: title, message: message)
            self.selectCurrentRow()
            self.splitMenuViewController?.closeMenu()
            break
        default:
            self.set(controllerType: item.controllerType)
        }
    }
    
    //MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.menu?.cells.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier, for: indexPath) as! STMenuMasterTableViewCell
        cell.configure(model: self.menu?.cells[indexPath.row])
        return cell
    }

}
 
extension STMenuMasterVC: IMasterViewController {
    
    func width(forPresentation splitViewController: STSplitViewController, traitCollection: UITraitCollection, size: CGSize) -> CGFloat {
        return 250
    }
    
}

extension STMenuMasterVC: ISyncManagerObserver {
    
    func syncManager(didStartSync syncManager: STSyncManager) {
        self.menu = Menu.current()
        self.reloadData()
    }
    
}

extension STMenuMasterVC: IDataBaseProviderProviderObserver {
    
    func dataBaseProvider(didUpdated provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {
        self.menu = Menu.current()
        self.reloadData()
    }

}


extension STMenuMasterVC {
    
    enum ControllerType: Int, CaseIterable {
        case gallery = 0
        case trash = 1
        case storage = 2
        case backupPhrase = 3
        case freeUpSpace = 4
        case settings = 5
        case lockApp = 7
        case officialWebsite = 8
        case signOut = 9
        
        var identifier: String {
            switch self {
            case .gallery:
                return "GalleryID"
            case .trash:
                return "TrashID"
            case .storage:
                return "StorageID"
            case .backupPhrase:
                return "BackupPhraseID"
            case .freeUpSpace:
                return "FreeUpSpaceID"
            case .settings:
                return "SettingsID"
            case .lockApp:
                return "LockAppID"
            case .officialWebsite:
                return "OfficialWebsiteID"
            case .signOut:
                return "SignOutID"
            }
        }
    }
    
    struct Menu {
        
        struct Header {
            let appName: String
            let userEmail: String
            let used: String
            let usedProgress: Float
        }
        
        struct Cell {
            let name: String?
            let icon: UIImage?
            let controllerType: ControllerType
        }
        
        let header: Header
        let cells: [Cell]
        
        static func current() -> Menu {
            let header = self.createHeader()
            let cell = self.createCells()
            let result = Menu(header: header, cells: cell)
            return result
        }
        
        private static func createHeader() -> Header {
            let user = STApplication.shared.dataBase.userProvider.user
            let info = STApplication.shared.dataBase.dbInfoProvider.dbInfo
            let appName = STEnvironment.current.appName
            let userEmail = user?.email ?? ""
            let usedSpace = Int64(Float(info.spaceUsed ?? "0") ?? 0)
            let allSpace = Int64(Float(info.spaceQuota ?? "0") ?? 0)
            let progress: Float = allSpace != 0 ? Float(usedSpace) / Float(allSpace) : 0
            let percent: Int = Int(progress * 100)
            let allSpaceGB = STBytesUnits(mb: allSpace)
            let used = String(format: "storage_space_used_info".localized, "\(usedSpace)", allSpaceGB.getReadableUnit(format: ".0f").uppercased(), "\(percent)")
            let header = Header(appName: appName, userEmail: userEmail, used: used, usedProgress: progress)
            return header
        }
        
        private static func createCells() -> [Cell] {
            let result = ControllerType.allCases.compactMap { (type) -> Cell in
                var name: String?
                var icon: UIImage?
                switch type {
                case .gallery:
                    name = "menu_gallery".localized
                    icon = UIImage(named: "ic_menu_gallery")
                case .trash:
                    name = "menu_trash".localized
                    icon = UIImage(named: "ic_menu_trash")
                case .storage:
                    name = "menu_storage".localized
                    icon = UIImage(named: "ic_menu_storage")
                case .backupPhrase:
                    name = "menu_backup_phrase".localized
                    icon = UIImage(named: "ic_menu_backup_phrase")
                case .freeUpSpace:
                    name = "menu_free_up_space".localized
                    icon = UIImage(systemName: "iphone.homebutton")
                case .settings:
                    name = "menu_settings".localized
                    icon = UIImage(named: "ic_menu_settings")
                case .lockApp:
                    name = "menu_lock_app".localized
                    icon = UIImage(named: "ic_menu_lock_app")
                case .officialWebsite:
                    name = "menu_official_website".localized
                    icon = UIImage(named: "ic_menu_official_website")
                case .signOut:
                    name = "menu_sign_out".localized
                    icon = UIImage(named: "ic_menu_sign_out")
                }
                return Cell(name: name, icon: icon, controllerType: type)
            }
            return result

        }
                
    }
    
}
