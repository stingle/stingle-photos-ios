//
//  STGalleryVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import UIKit
import Photos

extension STGalleryVC {
    
    struct ViewModel: ICollectionDataSourceViewModel {
                              
        typealias Header = STGaleryHeaderView
        typealias Cell = STGalleryCollectionViewCell
        typealias CDModel = STCDFile
        
        var isSelectedMode = false
        var selectedFileNames = Set<String>()
        
        func cellModel(for indexPath: IndexPath, data: STLibrary.File) -> CellModel {
            let image = STImageView.Image(file: data, isThumb: true)
            var videoDurationStr: String? = nil
            if let duration = data.decryptsHeaders.file?.videoDuration, duration > 0 {
                videoDurationStr = TimeInterval(duration).toString()
            }
            return CellModel(image: image,
                             name: data.file,
                             videoDuration: videoDurationStr,
                             isRemote: data.isRemote,
                             selectedMode: self.isSelectedMode,
                             isSelected: self.selectedFileNames.contains(data.file))
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
        let isSelected: Bool
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
                return "STGalleryCollectionViewCell"
            case .header:
                return "STGaleryHeaderView"
            }
        }
        
        var identifier: String {
            switch self {
            case .cell:
                return "STGalleryCollectionViewCellID"
            case .header:
                return "STGaleryHeaderViewID"
            }
        }
    }
        
}

class STGalleryVC: STFilesViewController<STGalleryVC.ViewModel> {
        
    @IBOutlet weak private var syncBarButtonItem: UIBarButtonItem!
    @IBOutlet weak private var syncView: STGallerySyncView!
    @IBOutlet weak private var selectButtonItem: UIBarButtonItem!
    
    private var viewModel = STGalleryVM()
    
    lazy private var accessoryView: STFilesActionTabBarAccessoryView = {
        let resilt = STFilesActionTabBarAccessoryView.loadNib()
        return resilt
    }()
    
    private lazy var pickerHelper: STImagePickerHelper = {
        return STImagePickerHelper(controller: self)
    }()
    
    @IBAction func didSelectSyncButton(_ sender: Any) {
        let controller = self.storyboard!.instantiateViewController(identifier: "Popover")
        controller.modalPresentationStyle = .popover
        let popController = controller.popoverPresentationController
        popController?.permittedArrowDirections = .any
        popController?.barButtonItem = self.syncBarButtonItem
        popController?.delegate = self
        self.showDetailViewController(controller, sender: nil)
    }
    
    @IBAction private func didSelectSelecedButtonItem(_ sender: UIBarButtonItem) {
        self.setSelectedMode(isSelected: !self.dataSource.viewModel.isSelectedMode)
    }
        
    //MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var inset = self.collectionView.contentInset
        inset.bottom = 30
        self.collectionView.contentInset = inset
        self.accessoryView.dataSource = self
        self.viewModel.sync()
        self.accessoryView.reloadData()
    }
    
    override func createDataSource() -> STCollectionViewDataSource<ViewModel> {
        let dbDataSource = self.viewModel.createDBDataSource()
        let viewModel = ViewModel()
        return STCollectionViewDataSource<ViewModel>(dbDataSource: dbDataSource,
                                                     collectionView: self.collectionView,
                                                     viewModel: viewModel)
    }
        
    override func configureLocalize() {
        super.configureLocalize()
        self.navigationItem.title = "gallery".localized
        self.navigationController?.tabBarItem.title = "gallery".localized
        
        self.emptyDataTitleLabel?.text = "empy_gallery_title".localized
        self.emptyDataSubTitleLabel?.text = "empy_gallery_message".localized
        self.selectButtonItem.title = self.dataSource.viewModel.isSelectedMode ? "cancel".localized : "select".localized
    }
    
    override func refreshControlDidRefresh() {
        self.viewModel.sync()
    }
    
    //MARK: - User action
    
    @IBAction private func didSelectOpenImagePicker(_ sender: Any) {
        self.pickerHelper.openPicker()
    }

    //MARK: - Layout

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
    
    //MARK: - Private
    
    private func setSelectedMode(isSelected: Bool) {
        self.dataSource.viewModel.selectedFileNames.removeAll()
        self.dataSource.viewModel.isSelectedMode = isSelected
        self.updateTabBarAccessoryView()
        self.selectButtonItem.title = self.dataSource.viewModel.isSelectedMode ? "cancel".localized : "select".localized
        self.collectionView.reloadData()
        self.updateSelectedItesmCount()
    }
    
    private func getSelectedFiles() -> [STLibrary.File] {
        let selectedFileNames = [String](self.dataSource.viewModel.selectedFileNames)
        guard !selectedFileNames.isEmpty else {
            return []
        }
        let files = self.viewModel.getFiles(fileNames: selectedFileNames)
        return files
    }
    
    private func updateSelectedItesmCount() {
        let count = self.dataSource.viewModel.selectedFileNames.count
        let title = count == 0 ? "select_items".localized : String(format: "selected_items_count".localized, "\(count)")
        self.accessoryView.title = title
        self.accessoryView.setEnabled(isEnabled: count != .zero)
    }
    
    private func updateTabBarAccessoryView() {
        if self.dataSource.viewModel.isSelectedMode {
            (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = self.accessoryView
        } else {
            (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = nil
        }
    }
    
    private func setSelectedItem(for indexPath: IndexPath) {
        guard let albumFile =  self.dataSource.object(at: indexPath) else {
            return
        }
        var isSelected = false
        if self.dataSource.viewModel.selectedFileNames.contains(albumFile.file) {
            self.dataSource.viewModel.selectedFileNames.remove(albumFile.file)
            isSelected = false
        } else {
            self.dataSource.viewModel.selectedFileNames.insert(albumFile.file)
            isSelected = true
        }
        let cell = (collectionView.cellForItem(at: indexPath) as? STGalleryCollectionViewCell)
        cell?.setSelected(isSelected: isSelected)
        self.updateSelectedItesmCount()
    }
    
    private func didSelectShareViaStinglePhotos() {
        let files = self.getSelectedFiles()
        guard !files.isEmpty else {
            return
        }
        let storyboard = UIStoryboard(name: "Shear", bundle: .main)
        let vc = (storyboard.instantiateViewController(identifier: "STSharedMembersNavVCID") as! UINavigationController)
        (vc.viewControllers.first as? STSharedMembersVC)?.shearedType = .files(files: files)
        self.showDetailViewController(vc, sender: nil)
    }
    
    private func openActivityViewController(downloadedUrls: [URL], folderUrl: URL?) {
        let vc = UIActivityViewController(activityItems: downloadedUrls, applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = self.accessoryView.barButtonItem(for: FileAction.share)
        vc.completionWithItemsHandler = { [weak self] (type,completed,items,error) in
            if let folderUrl = folderUrl {
                self?.viewModel.removeFileSystemFolder(url: folderUrl)
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
        }
    }
    
    //MARK: - Private actions
    
    private func showShareFileActionSheet(sender: UIBarButtonItem) {
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
    
    private func openDownloadController(action: FilesDownloadDecryptAction) {
        let files = self.getSelectedFiles()
        guard !files.isEmpty else {
            return
        }
        let shearing = STFilesDownloaderActivityVC.DownloadFiles.files(files: files)
        STFilesDownloaderActivityVC.showActivity(downloadingFiles: shearing, controller: self.tabBarController ?? self, delegate: self, userInfo: action)
    }
    
    private func deleteCurrentFile(files: [STLibrary.File]) {
        guard !files.isEmpty else {
            return
        }
        STLoadingView.show(in: self.view)
        self.viewModel.deleteFile(files: files) { [weak self] error in
            guard let weakSelf = self else{
                return
            }
            STLoadingView.hide(in: weakSelf.view)
            if let error = error {
                weakSelf.showError(error: error)
            } else {
                weakSelf.setSelectedMode(isSelected: false)
            }
        }
    }
    
}

extension STGalleryVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.dataSource.viewModel.isSelectedMode {
            self.setSelectedItem(for: indexPath)
        } else {
            guard let file = self.dataSource.object(at: indexPath) else {
                return
            }
            let vc = STFileViewerVC.create(galery: [#keyPath(STCDFile.dateCreated)], predicate: nil, file: file)
            self.show(vc, sender: nil)
        }
    }
    
}

extension STGalleryVC: STImagePickerHelperDelegate {
    
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

extension STGalleryVC: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}

extension STGalleryVC: STFilesActionTabBarAccessoryViewDataSource {
    
    enum FilesDownloadDecryptAction {
        case share
        case saveDevicePhotos
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
                return "trash"
            }
        }
        
    }
    
    func accessoryView(actions accessoryView: STFilesActionTabBarAccessoryView) -> [STFilesActionTabBarAccessoryView.ActionItem] {
        
        var items = [STFilesActionTabBarAccessoryView.ActionItem]()
        
        let share = STFilesActionTabBarAccessoryView.ActionItem.share(identifier: FileAction.share) { [weak self] _ , buttonItem  in
            self?.didSelectShare(sendner: buttonItem)
        }
        items.append(share)
        
        let move = STFilesActionTabBarAccessoryView.ActionItem.move(identifier: FileAction.move) { [weak self] _, buttonItem in
            self?.didSelectMove(sendner: buttonItem)
        }
        items.append(move)
        
        let saveToDevice = STFilesActionTabBarAccessoryView.ActionItem.saveToDevice(identifier: FileAction.saveToDevice) { [weak self] _, buttonItem in
            self?.didSelectSaveToDevice(sendner: buttonItem)
        }
        items.append(saveToDevice)
        
        let trash = STFilesActionTabBarAccessoryView.ActionItem.trash(identifier: FileAction.trash) { [weak self] _, buttonItem in
            self?.didSelectTrash(sendner: buttonItem)
        }
        items.append(trash)
        return items
    }
    
    
}

extension STGalleryVC {
    
    private func didSelectShare(sendner: UIBarButtonItem) {
        self.showShareFileActionSheet(sender: sendner)
    }
    
    private func didSelectMove(sendner: UIBarButtonItem) {
        let files = self.getSelectedFiles()
        guard !files.isEmpty else {
            return
        }
        let navVC = self.storyboard?.instantiateViewController(identifier: "goToMoveAlbumFiles") as! UINavigationController
        (navVC.viewControllers.first as? STMoveAlbumFilesVC)?.moveInfo = .files(files: files)
        self.showDetailViewController(navVC, sender: nil)
    }
    
    private func didSelectSaveToDevice(sendner: UIBarButtonItem) {
        let title = "alert_save_to_device_library_title".localized
        let message = "alert_save_files_to_device_library_message".localized
        self.showInfoAlert(title: title, message: message, cancel: true) { [weak self] in
            self?.openDownloadController(action: .saveDevicePhotos)
        }
    }
    
    private func didSelectTrash(sendner: UIBarButtonItem) {
        let files = self.getSelectedFiles()
        let title = "delete_files_alert_title".localized
        let message = String(format: "delete_move_files_alert_message".localized, "\(files.count)")
        self.showOkCancelAlert(title: title, message: message, handler: { [weak self] _ in
            self?.deleteCurrentFile(files: files)
        })
    }
    
}

extension STGalleryVC: STFilesDownloaderActivityVCDelegate {
    
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
