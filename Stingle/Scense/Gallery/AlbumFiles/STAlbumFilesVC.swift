//
//  STAlbumFilesVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/19/21.
//

import UIKit
import Photos

extension STAlbumFilesVC {
    
    struct ViewModel: ICollectionDataSourceViewModel {
                              
        typealias Header = STAlbumFilesHeaderView
        typealias Cell = STAlbumFilesCollectionViewCell
        typealias CDModel = STCDAlbumFile
        
        let album: STLibrary.Album
        var isSelectedMode = false
                
        init(album: STLibrary.Album) {
            self.album = album
        }
        
        func cellModel(for indexPath: IndexPath, data: STLibrary.AlbumFile) -> CellModel {
            let image = STImageView.Image(album: self.album, albumFile: data, isThumb: true)
            var videoDurationStr: String? = nil
            if let duration = data.decryptsHeaders.file?.videoDuration, duration > 0 {
                videoDurationStr = TimeInterval(duration).timeFormat()
            }
            return CellModel(image: image,
                             name: data.file,
                             videoDuration: videoDurationStr,
                             isRemote: data.isRemote,
                             selectedMode: self.isSelectedMode)
        }
        
        func headerModel(for indexPath: IndexPath, section: String) -> HeaderModel {
            return HeaderModel(text: section)
        }
    }
    
    struct CellModel: IViewDataSourceCellModel {
        let identifier: Identifier = .cell
        let image: STImageView.Image?
        let name: String?
        let videoDuration: String?
        let isRemote: Bool
        let selectedMode: Bool
    }
    
    struct HeaderModel: IViewDataSourceHeaderModel {
        let identifier: Identifier = .header
        let text: String?
    }
    
    enum Identifier: CaseIterable, IViewDataSourceItemIdentifier {
        case cell
        case header
        
        var nibName: String {
            switch self {
            case .cell:
                return "STAlbumFilesCollectionViewCell"
            case .header:
                return "STAlbumFilesHeaderView"
            }
        }
        
        var identifier: String {
            switch self {
            case .cell:
                return "STAlbumFilesCollectionViewCellID"
            case .header:
                return "STAlbumFilesHeaderViewID"
            }
        }
    }
        
}

class STAlbumFilesVC: STFilesSelectionViewController<STAlbumFilesVC.ViewModel> {
    
    @IBOutlet weak private var addItemButton: UIButton!
    @IBOutlet weak private var selectButtonItem: UIBarButtonItem!
    @IBOutlet private var albumSettingsButtonItem: UIBarButtonItem!
    @IBOutlet weak private var moreBarButtonItem: UIBarButtonItem!
    
    var album: STLibrary.Album!
    
    private var viewModel: STAlbumFilesVM!
    
    private lazy var pickerHelper: STImagePickerHelper = {
        return STImagePickerHelper(controller: self)
    }()
    
    lazy private var accessoryView: STFilesActionTabBarAccessoryView = {
        let resilt = STFilesActionTabBarAccessoryView.loadNib()
        return resilt
    }()
    
    override func viewDidLoad() {
        self.viewModel = STAlbumFilesVM(album: self.album)
        self.viewModel.delegate = self
        super.viewDidLoad()
        self.accessoryView.dataSource = self
        self.configureAlbumActionView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateTabBarAccessoryView()
    }
    
    override func configureLocalize() {
        self.navigationItem.title = self.album.albumMetadata?.name
        self.emptyDataTitleLabel?.text = "empy_gallery_title".localized
        self.emptyDataSubTitleLabel?.text = "empy_gallery_message".localized
        self.selectButtonItem.title = "select".localized
    }
    
    override func dataSource(didApplySnapshot dataSource: IViewDataSource) {
        super.dataSource(didApplySnapshot: dataSource)
        self.configureAlbumActionView()
    }
    
    override func refreshControlDidRefresh() {
        super.refreshControlDidRefresh()
        self.viewModel.sync()
    }
    
    override func createDataSource() -> STCollectionViewDataSource<ViewModel> {
        let dbDataSource = self.viewModel.createDBDataSource()
        let viewModel = ViewModel(album: self.album)
        return STCollectionViewDataSource<ViewModel>(dbDataSource: dbDataSource,
                                                     collectionView: self.collectionView,
                                                     viewModel: viewModel)
    }
    
    override func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let inset: CGFloat = 4
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 5 : layoutEnvironment.container.contentSize.width > layoutEnvironment.container.contentSize.height ? 4 : 3
        let item = self.dataSource.generateCollectionLayoutItem()
        let itemSizeWidth = (layoutEnvironment.container.contentSize.width - 2 * inset) / CGFloat(lineCount)
        let itemSizeHeight = itemSizeWidth
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemSizeHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: lineCount)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        group.interItemSpacing = .fixed(inset)
                
        let section = NSCollectionLayoutSection(group: group)
        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),  heightDimension: .absolute(38))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        sectionHeader.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 9, bottom: 0, trailing: 9)
        section.boundarySupplementaryItems = [sectionHeader]
        section.contentInsets = .zero
        section.interGroupSpacing = inset
        section.removeContentInsetsReference(safeAreaInsets: self.collectionView.window?.safeAreaInsets)
        return section
    }
    
    override func setSelectionMode(isSelectionMode: Bool) {
        guard self.isSelectionMode != isSelectionMode else {
            return
        }
        self.dataSource.viewModel.isSelectedMode = isSelectionMode
        super.setSelectionMode(isSelectionMode: isSelectionMode)
        self.updateTabBarAccessoryView()
        self.selectButtonItem.title = self.dataSource.viewModel.isSelectedMode ? "cancel".localized : "select".localized
        self.updateSelectedItesmCount()
    }
    
    override func updatedSelect(for indexPath: IndexPath, isSlected: Bool) {
        super.updatedSelect(for: indexPath, isSlected: isSlected)
        self.updateSelectedItesmCount()
    }
    
    override func collectionView(didSelectItemAt indexPath: IndexPath) {
        guard !self.isSelectionMode, let file = self.dataSource.object(at: indexPath) else {
            return
        }
        let sorting = self.viewModel.getSorting()
        let vc = STFileViewerVC.create(album: self.album, file: file, sortDescriptorsKeys: sorting)
        self.show(vc, sender: nil)
    }
    
    //MARK: - UserAction
    
    @IBAction private func didSelectMoreButton(_ sender: UIBarButtonItem) {
        let fileNames = self.isSelectionMode ? [String](self.selectionObjectsIdentifiers) : nil
        var actions = [STAlbumFilesVC.AlbumAction]()
        do {
            actions = try self.viewModel.getAlbumAction(fileNames: fileNames)
        } catch {
            if let error = error as? IError {
                self.showError(error: error)
            }
            return
        }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actions.forEach { action in
            let action = UIAlertAction(title: action.localized, style: .default) { [weak self] _ in
                self?.didSelectShitAction(action: action)
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(cancelAction)
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        self.showDetailViewController(alert, sender: nil)
    }
    
    @IBAction private func didSelectAlbumSettingsButton(_ sender: UIBarButtonItem) {
        if !self.album.isShared {
            let storyboard = UIStoryboard(name: "Shear", bundle: .main)
            let vc = (storyboard.instantiateViewController(identifier: "STSharedMembersNavVCID") as! UINavigationController)
            
            let sharedMembersVC = (vc.viewControllers.first as? STSharedMembersVC)
            sharedMembersVC?.shearedType = .album(album: self.album)
            
            sharedMembersVC?.complition = { [weak self] success in
                if success {
                    self?.setSelectionMode(isSelectionMode: false)
                }
            }
            
            self.showDetailViewController(vc, sender: nil)
        } else {
            let storyboard = UIStoryboard(name: "Shear", bundle: .main)
            let vc = (storyboard.instantiateViewController(identifier: "STSharedAlbumSettingsVCID") as! UINavigationController)
            (vc.viewControllers.first as? STSharedAlbumSettingsVC)?.album = self.album
            self.show(vc, sender: nil)
        }
    }
    
    @IBAction private func didSelectAddButton(_ sender: Any) {
        self.pickerHelper.openPicker()
    }
    
    @IBAction private func didSelectButtonItem(_ sender: UIBarButtonItem) {
        self.setSelectionMode(isSelectionMode: !self.isSelectionMode)
    }
    
    //MARK: - Private
        
    private func didSelectShitAction(action: AlbumAction) {
        let loadingView: UIView =  self.navigationController?.view ?? self.view
        func didResiveResult(error: IError?) {
            STLoadingView.hide(in: loadingView)
            if let error = error {
                self.showError(error: error)
            }
            self.setSelectionMode(isSelectionMode: false)
        }
        
        switch action {
        case .rename:
            let placeholder = "album_name".localized
            let title = "rename_album".localized
            
            self.showOkCancelAlert(title: title, message: nil) { [weak self] textField in
                textField.text =  self?.album.albumMetadata?.name
                textField.placeholder = placeholder
            } handler: { [weak self] newName in
                STLoadingView.show(in: loadingView)
                self?.viewModel.renameAlbum(newName: newName, result: { error in
                    didResiveResult(error: error)
                })
            }
 
        case .setBlankCover:
            STLoadingView.show(in: loadingView)
            self.viewModel.setBlankCover { error in
                didResiveResult(error: error)
            }
        case .resetBlankCover:
            STLoadingView.show(in: loadingView)
            self.viewModel.resetBlankCover { error in
                didResiveResult(error: error)
            }
        case .delete:
            let title = String(format: "delete_album_alert_title".localized, album.albumMetadata?.name ?? "")
            let message = String(format: "delete_album_alert_message".localized, album.albumMetadata?.name ?? "")
            self.showOkCancelAlert(title: title, message: message, handler: { [weak self] _ in
                STLoadingView.show(in: loadingView)
                self?.viewModel.delete { error in
                    didResiveResult(error: error)
                }
            })
        case .leave:
            STLoadingView.show(in: loadingView)
            self.showOkCancelAlert(title: "leave".localized, message: "leave_album_alert_message".localized, handler: { [weak self] _ in
                self?.viewModel.leave { error in
                    didResiveResult(error: error)
                }
            })
        case .setCover:
            STLoadingView.show(in: loadingView)
            let fileName = self.selectionObjectsIdentifiers.first ?? ""
            self.viewModel.setCover(fileName: fileName) { error in
                didResiveResult(error: error)
            }
        case .downloadSelection:
            let fileName = [String](self.selectionObjectsIdentifiers)
            self.viewModel.downloadSelection(fileNames: fileName)
            self.setSelectionMode(isSelectionMode: false)
        }
        
    }
    
    private func updateSelectedItesmCount() {
        let count = self.selectionObjectsIdentifiers.count
        let title = count == 0 ? "select_items".localized : String(format: "selected_items_count".localized, "\(count)")
        self.accessoryView.title = title
        self.accessoryView.setEnabled(isEnabled: count != .zero)
    }
    
    private func updateTabBarAccessoryView() {
        if self.isSelectionMode {
            (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = self.accessoryView
        } else {
            (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = nil
        }
    }

    private func configureAlbumActionView() {
        self.addItemButton.isHidden = !(self.album.permission.allowAdd || self.album.isOwner)
        self.accessoryView.reloadData()
        var image: UIImage?
        if !self.album.isShared {
            image = UIImage(named: "ic_shared_album_min")
        } else if self.album.isOwner {
            image = UIImage(named: "ic_album_settings")
        } else {
            image = UIImage(named: "ic_album_info")
        }
        self.albumSettingsButtonItem.image = image
    }
    
    private func deleteSelectedFiles() {
        STLoadingView.show(in: self.view)
        let files: [String] = [String](self.selectionObjectsIdentifiers)
        self.viewModel.deleteFiles(identifiers: files) { [weak self] error in
            guard let weakSelf = self else{
                return
            }
            STLoadingView.hide(in: weakSelf.view)
            if let error = error {
                weakSelf.showError(error: error)
            } else {
                self?.setSelectionMode(isSelectionMode: false)
            }
        }
    }
    
    private func showShareFilesActionSheet(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "share".localized, message: nil, preferredStyle: .actionSheet)
        let stinglePhotos = UIAlertAction(title: "share_via_stingle_photos".localized, style: .default) { [weak self] _ in
            self?.didSelectShareViaStinglePhotos()
        }
        alert.addAction(stinglePhotos)
        
        let shareOtherApps = UIAlertAction(title: "share_to_other_apps".localized, style: .default) { [weak self] _ in
            self?.openDownloadController(action: .share)
        }
        alert.addAction(shareOtherApps)
        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(cancelAction)
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        self.showDetailViewController(alert, sender: nil)
    }
    
    private func didSelectShareViaStinglePhotos() {
        let selectedFileNames = [String](self.selectionObjectsIdentifiers)
        guard !selectedFileNames.isEmpty else {
            return
        }
        let files = self.viewModel.getFiles(fileNames: selectedFileNames)
        let storyboard = UIStoryboard(name: "Shear", bundle: .main)
        let vc = (storyboard.instantiateViewController(identifier: "STSharedMembersNavVCID") as! UINavigationController)
        
        let sharedMembersVC = (vc.viewControllers.first as? STSharedMembersVC)
        
        sharedMembersVC?.complition = { [weak self] success in
            if success {
                self?.setSelectionMode(isSelectionMode: false)
            }
        }
        
        sharedMembersVC?.shearedType = .albumFiles(album: self.album, files: files)
        self.showDetailViewController(vc, sender: nil)
    }
    
    private func openActivityViewController(downloadedUrls: [URL], folderUrl: URL?) {
        let vc = UIActivityViewController(activityItems: downloadedUrls, applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = self.accessoryView.barButtonItem(for: FileAction.share)
        vc.completionWithItemsHandler = { [weak self] (type,completed,items,error) in
            if let folderUrl = folderUrl {
                self?.viewModel.removeFileSystemFolder(url: folderUrl)
            }
            if completed {
                self?.setSelectionMode(isSelectionMode: false)
            }
        }
        self.present(vc, animated: true)
    }
    
    private func saveItemsToDevice(downloadeds: [STFilesDownloaderActivityVM.DecryptDownloadFile], folderUrl: URL?) {
        var filesSave = [(url: URL, itemType: STImagePickerHelper.ItemType)]()
        downloadeds.forEach { file in
            let type: STImagePickerHelper.ItemType = file.header.fileOreginalType == .image ? .photo : .video
            let url = file.url
            filesSave.append((url, type))
        }
        self.pickerHelper.save(items: filesSave) { [weak self] in
            if let folderUrl = folderUrl {
                self?.viewModel.removeFileSystemFolder(url: folderUrl)
            }
            DispatchQueue.main.async {
                self?.setSelectionMode(isSelectionMode: false)
            }
        }
    }
    
    private func openDownloadController(action: FilesDownloadDecryptAction) {
        let selectedFileNames = [String](self.selectionObjectsIdentifiers)
        guard !selectedFileNames.isEmpty else {
            return
        }
        let files = self.viewModel.getFiles(fileNames: selectedFileNames)
        let shearing = STFilesDownloaderActivityVC.DownloadFiles.albumFiles(album: self.album, files: files)
        STFilesDownloaderActivityVC.showActivity(downloadingFiles: shearing, controller: self.tabBarController ?? self, delegate: self, userInfo: action)
    }
        
}

extension STAlbumFilesVC: STImagePickerHelperDelegate {
    
    func pickerViewController(_ imagePickerHelper: STImagePickerHelper, didPickAssets assets: [PHAsset]) {
        let importer = self.viewModel.upload(assets: assets)
        
        let progressView = STProgressView()
        progressView.title = "importing".localized
        
        let view: UIView = self.navigationController?.view ?? self.view
        progressView.show(in: view)
    
        importer.startHendler = { progress in
            let progressValue = progress.totalUnitCount == .zero ? .zero : Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    progressView.progress = progressValue
                    progressView.subTitle = "\(progress.completedUnitCount + 1)/\(progress.totalUnitCount)"
                }
            }
        }
        
        importer.progressHendler = { progress in
            let progressValue = progress.totalUnitCount == .zero ? .zero : Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    progressView.progress = progressValue
                    progressView.subTitle = "\(progress.completedUnitCount + 1)/\(progress.totalUnitCount)"
                }
            }
        }
        
        importer.complition = { _ in
            DispatchQueue.main.async {
                progressView.hide()
            }
        }
        
    }
    
}

extension STAlbumFilesVC: STFilesDownloaderActivityVCDelegate {
    
    func filesDownloaderActivity(didEndDownload activity: STFilesDownloaderActivityVC, decryptDownloadFiles: [STFilesDownloaderActivityVM.DecryptDownloadFile], folderUrl: URL?) {
        guard let decryptAction = activity.userInfo as? FilesDownloadDecryptAction else {
            if let folderUrl = folderUrl {
                self.viewModel.removeFileSystemFolder(url: folderUrl)
            }
            return
        }
        switch decryptAction {
        case .share:
            let urls = decryptDownloadFiles.compactMap({return $0.url})
            self.openActivityViewController(downloadedUrls: urls, folderUrl: folderUrl)
        case .saveDevicePhotos:
            self.saveItemsToDevice(downloadeds: decryptDownloadFiles, folderUrl: folderUrl)
        }
    }
}

extension STAlbumFilesVC: STFilesActionTabBarAccessoryViewDataSource {
    
    func accessoryView(actions accessoryView: STFilesActionTabBarAccessoryView) -> [STFilesActionTabBarAccessoryView.ActionItem] {
      
        var items = [STFilesActionTabBarAccessoryView.ActionItem]()
        if self.album.isOwner {
           
            let share = STFilesActionTabBarAccessoryView.ActionItem.share(identifier: FileAction.share) { [weak self] _ , buttonItem  in
                self?.didSelectShare(files: buttonItem)
            }
            items.append(share)
            
            let move = STFilesActionTabBarAccessoryView.ActionItem.move(identifier: FileAction.move) { [weak self] _, buttonItem in
                self?.didSelectMoveButton(files: buttonItem)
            }
            items.append(move)
            
            let saveToDevice = STFilesActionTabBarAccessoryView.ActionItem.saveToDevice(identifier: FileAction.saveToDevice) { [weak self] _, buttonItem in
                self?.didSelectSaveToDeviceButton(files: buttonItem)
            }
            items.append(saveToDevice)
            
            let trash = STFilesActionTabBarAccessoryView.ActionItem.trash(identifier: FileAction.trash) { [weak self] _, buttonItem in
                self?.didSelectTrashButton(files: buttonItem)
            }
            
            items.append(trash)

        } else {
            
            if self.album.permission.allowShare {
                let share = STFilesActionTabBarAccessoryView.ActionItem.share(identifier: FileAction.share) { [weak self] _ , buttonItem  in
                    self?.didSelectShare(files: buttonItem)
                }
                items.append(share)
            }
            
            if self.album.permission.allowCopy {
                let move = STFilesActionTabBarAccessoryView.ActionItem.move(identifier: FileAction.move) { [weak self] _, buttonItem in
                    self?.didSelectMoveButton(files: buttonItem)
                }
                items.append(move)
                
                let saveToDevice = STFilesActionTabBarAccessoryView.ActionItem.saveToDevice(identifier: FileAction.saveToDevice) { [weak self] _, buttonItem in
                    self?.didSelectSaveToDeviceButton(files: buttonItem)
                }
                items.append(saveToDevice)
            }
            
        }
        return items
        
    }
    
}


extension STAlbumFilesVC {
    
    private func didSelectShare(files sendner: UIBarButtonItem) {
        self.showShareFilesActionSheet(sender: sendner)
    }
    
    private func didSelectMoveButton(files sendner: UIBarButtonItem) {
        let selectedFileNames = [String](self.selectionObjectsIdentifiers)
        let navVC = self.storyboard?.instantiateViewController(identifier: "goToMoveAlbumFiles") as! UINavigationController
        let moveAlbumFilesVC = (navVC.viewControllers.first as? STMoveAlbumFilesVC)
        moveAlbumFilesVC?.moveInfo = .albumFiles(album: self.album, files: self.viewModel.getFiles(fileNames: selectedFileNames))
        moveAlbumFilesVC?.complition = { [weak self] success in
            if success {
                self?.setSelectionMode(isSelectionMode: false)
            }
        }
        self.showDetailViewController(navVC, sender: nil)
    }
    
    private func didSelectSaveToDeviceButton(files sendner: UIBarButtonItem) {
        let title = "alert_save_to_device_library_title".localized
        let message = "alert_save_files_to_device_library_message".localized
        self.showInfoAlert(title: title, message: message, cancel: true) { [weak self] in
            self?.openDownloadController(action: .saveDevicePhotos)
        }
    }
    
    private func didSelectTrashButton(files sendner: UIBarButtonItem) {
        let count = self.selectionObjectsIdentifiers.count
        let title = "delete_files_alert_title".localized
        let message = String(format: "delete_move_files_alert_message".localized, "\(count)")
        self.showOkCancelAlert(title: title, message: message, handler: { [weak self] _ in
            self?.deleteSelectedFiles()
        })
    }
    
}

extension STAlbumFilesVC: STAlbumFilesVMDelegate {
    
    func albumFilesVM(didDeletedAlbum albumFilesVM: STAlbumFilesVM) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func albumFilesVM(didUpdatedAlbum albumFilesVM: STAlbumFilesVM, album: STLibrary.Album) {
        self.album = album
        self.configureAlbumActionView()
        self.configureLocalize()
    }
    
}


extension STAlbumFilesVC {
    
    enum FilesDownloadDecryptAction {
        case share
        case saveDevicePhotos
    }
    
    enum AlbumAction {
        
        case rename
        case setBlankCover
        case resetBlankCover
        case delete
        case leave
        case setCover
        case downloadSelection
        
        var localized: String {
            switch self {
            case .rename:
                return "rename_album".localized
            case .setBlankCover:
                return "set_blank_album_cover".localized
            case .resetBlankCover:
                return "reset_album_cover".localized
            case .delete:
                return "delate_album".localized
            case .leave:
                return "leave_album".localized
            case .setCover:
                return "set_album_cover".localized
            case .downloadSelection:
                return "download_selection".localized
            }

        }
            
    }
    
    enum FileAction: StringPointer {
        
        case share
        case move
        case saveToDevice
        case trash
        
        var stringValue: String {
            switch self {
            case .share:
                return "share"
            case .move:
                return "move"
            case .saveToDevice:
                return "saveToDevice"
            case .trash:
                return "trashBu"
            }
        }
    }
    
}
