//
//  STSharedAlbumSettingsVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/17/21.
//

import UIKit

extension STSharedAlbumSettingsVC {
    
    enum TableItem: CaseIterable {
        
        case nameCell
        case permissionCell
        case addMemberCell
        case memberCell
       
        var identifier: String {
            switch self {
            case .nameCell:
                return "nameCell"
            case .permissionCell:
                return "permissionCell"
            case .addMemberCell:
                return "addMemberCell"
            case .memberCell:
                return "memberCell"
            }
        }
        
        var nibName: String {
            switch self {
            case .nameCell:
                return "STAlbumSettingsNameCell"
            case .permissionCell:
                return "STAlbumSettingsPermissionCell"
            case .addMemberCell:
                return "STAlbumSettingsAddMemberCell"
            case .memberCell:
                return "STAlbumSettingsMemberCell"
            }
        }
        
    }
        
    struct TableViewModel {
        
        enum PermissionType {
            case allowAdd
            case allowShare
            case allowCopy
        }
                
        struct Section {
            let header: String?
            let cells: [ISharedAlbumSettingsItemModel]
        }
        
        var sections: [Section]
        
        init(album: STLibrary.Album, members: [STContact], permission: STLibrary.Album.Permission) {
            
            self.sections = [Section]()
            let name = self.generateNameSection(album: album)
            let permission = self.generatePermissionSection(album: album, permission: permission)
            let members = self.generateMembersSection(album: album, members: members)
                        
            self.sections.append(name)
            self.sections.append(permission)
            self.sections.append(members)
        }
        
        //MARK: - Private
        
        private func generateNameSection(album: STLibrary.Album) -> Section {
            let isOwner = album.isOwner
            let nameItemButtonTitle = isOwner ? "unshare".localized : "leave_album".localized
            let name = STAlbumSettingsNameCellModel(title: "shared_album".localized, name: album.albumMetadata?.name, buttonTitle: nameItemButtonTitle)
            return Section(header: nil, cells: [name])
        }
        
        private func generatePermissionSection(album: STLibrary.Album, permission: STLibrary.Album.Permission) -> Section {
            
            let isEnabled = album.isOwner
            
            let addNewPhotos = STAlbumSettingsPermissionCellModel(id: PermissionType.allowAdd,
                                                                  permission: permission.allowAdd,
                                                                  isEnabled: isEnabled,
                                                                  title: "permition_add_new_photos".localized,
                                                                  subTitle: "permition_add_new_photos_description".localized)
            
            
            let sharing = STAlbumSettingsPermissionCellModel(id: PermissionType.allowShare,
                                                             permission: permission.allowShare,
                                                             isEnabled: isEnabled,
                                                             title: "permition_sharing".localized,
                                                             subTitle: "permition_sharing_description".localized)
            
            let copying = STAlbumSettingsPermissionCellModel(id: PermissionType.allowCopy,
                                                             permission: permission.allowCopy,
                                                             isEnabled: isEnabled,
                                                             title: "permition_copying".localized,
                                                             subTitle: "permition_copying_description".localized)
            
            let items = [addNewPhotos, sharing, copying]
            return Section(header: "permissions".localized, cells: items)
        }
        
        private func generateMembersSection(album: STLibrary.Album,  members: [STContact]) -> Section {
            var items = [ISharedAlbumSettingsItemModel]()
            let isEnabled = album.isOwner
            let addMember = STAlbumSettingsAddMemberCellModel(isEnabled: album.permission.allowShare || album.isOwner)
            items.append(addMember)
            let membersItems = members.compactMap { contact in
                return STAlbumSettingsMemberCellModel(id: contact.userId, isEnabled: isEnabled, email: contact.email)
            }
            items.append(contentsOf: membersItems)
            return Section(header: "members".localized, cells: items)
        }
        
    }
    
}

class STSharedAlbumSettingsVC: UIViewController {
    
    var album: STLibrary.Album!
    
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak private var saveBarButtonItem: UIBarButtonItem!
    
    private let headerIdentifier = "Header"
    private var tableViewModel: TableViewModel!
    private var viewModel: STSharedAlbumSettingsVM!
    private var permission: STLibrary.Album.Permission!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.saveBarButtonItem.isEnabled = false
        self.viewModel = STSharedAlbumSettingsVM(album: self.album)
        self.viewModel.delegate = self
        self.configureLocalized()
        self.configureTableItems()
        self.configureTableView()
    }
    
    //MARK: - Private
    
    private func configureLocalized() {
        self.saveBarButtonItem.title = "save".localized
        self.navigationItem.title = self.album.isOwner ? "album_settings".localized : "album_info".localized
    }
    
    private func configureTableItems() {
        let members = self.viewModel.getMembers()
        self.permission = self.album.permission
        self.tableViewModel = TableViewModel(album: self.album, members: members, permission: self.permission)
    }
    
    private func configureTableView() {
        let nib = UINib(nibName: "STAlbumSettingsHeader", bundle: .main)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: self.headerIdentifier)
        TableItem.allCases.forEach { item in
            let nib = UINib(nibName: item.nibName, bundle: .main)
            self.tableView.register(nib, forCellReuseIdentifier: item.identifier)
        }
    }
    
    private func removeMember(memberID: String) {
        STLoadingView.show(in: self.view)
        self.viewModel.removeMember(memberID: memberID) { [weak self] error in
            guard let weakSelf = self else{
                return
            }
            STLoadingView.hide(in: weakSelf.view)
            if let error = error {
                weakSelf.showError(error: error)
            }
        }
    }
    
    private func leaveAlbumRequest() {
        STLoadingView.show(in: self.view)
        self.viewModel.leaveAlbum { [weak self] error in
            guard let weakSelf = self else{
                return
            }
            STLoadingView.hide(in: weakSelf.view)
            if let error = error {
                weakSelf.showError(error: error)
            }
        }
    }

    private func unshareAlbumRequest() {
        STLoadingView.show(in: self.view)
        self.viewModel.unshareAlbum { [weak self] error in
            guard let weakSelf = self else{
                return
            }
            STLoadingView.hide(in: weakSelf.view)
            if let error = error {
                weakSelf.showError(error: error)
            } else {
                weakSelf.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func unshareAlbum() {
        let title = "stop_sharing".localized
        let message = String(format: "alert_stop_sharing_message".localized, self.album.albumMetadata?.name ?? "")
        self.showInfoAlert(title: title, message: message, cancel: true) { [weak self] in
            self?.unshareAlbumRequest()
        }
    }
    
    private func leaveAlbum() {
        let title = "leave".localized
        let message = "leave_album_alert_message".localized
        self.showInfoAlert(title: title, message: message, cancel: true) { [weak self] in
            self?.leaveAlbumRequest()
        }
    }
    
    private func updatePermission() {
        STLoadingView.show(in: self.view)
        self.viewModel.updatePermission(permission: self.permission) { [weak self] error in
            guard let weakSelf = self else{
                return
            }
            STLoadingView.hide(in: weakSelf.view)
            if let error = error {
                weakSelf.showError(error: error)
            }
        }
    }
        
    //MARK: - UserAction
    
    @IBAction private func didSelectCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func didSelectSaveButton(_ sender: UIBarButtonItem) {
        self.updatePermission()
    }
    
}

extension STSharedAlbumSettingsVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableViewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewModel.sections[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = self.tableViewModel.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellModel.itemType.identifier, for: indexPath)
        
        let settingsCell = cell as! ISharedAlbumSettingsCell
        settingsCell.delegate = self
        settingsCell.configure(model: cellModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cellModel = self.tableViewModel.sections[section]
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.headerIdentifier) as! STAlbumSettingsHeader
        headerView.configure(title: cellModel.header)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let headerTitle = self.tableViewModel.sections[section].header
        let result = headerTitle == nil ? 0 : UITableView.automaticDimension
        return result
    }
        
}

extension STSharedAlbumSettingsVC: STSharedAlbumSettingsCellDelegate {
    
    func sharedAlbumSettingsCell(cell: ISharedAlbumSettingsCell, didSelectRemoveMember model: ISharedAlbumSettingsItemModel) {
        guard let model = model as? STAlbumSettingsMemberCellModel, let userID = model.id as? String, let member = self.viewModel.getContacts(contactsIds: [userID]).first else {
            return
        }
        
        let title = "alert_remove_album_member_title".localized
        let message = String.init(format: "alert_remove_album_member_message".localized, member.email)
        self.showInfoAlert(title: title, message: message, cancel: true) { [weak self] in
            self?.removeMember(memberID: userID)
        }
    }
    
    func sharedAlbumSettingsCell(cell: ISharedAlbumSettingsCell, didSelectAddMember model: ISharedAlbumSettingsItemModel) {
        let vc = self.storyboard?.instantiateViewController(identifier: "STSharedMembersVCID") as! STSharedMembersVC
        vc.shearedType = .album(album: self.album)
        self.show(vc, sender: nil)
    }
    
    func sharedAlbumSettingsCell(cell: ISharedAlbumSettingsCell, didSelectShare model: ISharedAlbumSettingsItemModel) {
        if self.album.isOwner {
            self.unshareAlbum()
        } else {
            self.leaveAlbum()
        }
    }
    
    func sharedAlbumSettingsCell(cell: ISharedAlbumSettingsCell, didSelectPermission model: ISharedAlbumSettingsItemModel, isOn: Bool) {
        guard let model = model as? STAlbumSettingsPermissionCellModel, let type = model.id as? TableViewModel.PermissionType else {
            return
        }
        switch type {
        case .allowAdd:
            self.permission = STLibrary.Album.Permission(allowAdd: isOn, allowShare: self.permission.allowShare, allowCopy: self.permission.allowCopy)
        case .allowShare:
            self.permission = STLibrary.Album.Permission(allowAdd: self.permission.allowAdd, allowShare: isOn, allowCopy: self.permission.allowCopy)
        case .allowCopy:
            self.permission = STLibrary.Album.Permission(allowAdd: self.permission.allowAdd, allowShare: self.permission.allowShare, allowCopy: isOn)
        }
        self.saveBarButtonItem.isEnabled = self.permission != self.album.permission
    }
    
}

extension STSharedAlbumSettingsVC: STSharedAlbumSettingsVMDelegate {
    
    func sharedAlbumSettingsVM(albumDidDeleted provider: STSharedAlbumSettingsVM) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func sharedAlbumSettingsVM(albumDidUpdated provider: STSharedAlbumSettingsVM, album: STLibrary.Album) {
        self.album = album
        let members = self.viewModel.getMembers()
        self.tableViewModel = TableViewModel(album: self.album, members: members, permission: self.permission)
        self.tableView.reloadData()
        self.saveBarButtonItem.isEnabled = self.permission != self.album.permission
    }
    
    
}
