//
//  STGalleryVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import UIKit
import Photos
import StingleRoot

extension STGalleryVC {
    
    struct ViewModel: ICollectionDataSourceViewModel {
                              
        typealias Header = STGaleryHeaderView
        typealias Cell = STGalleryCollectionViewCell
        typealias CDModel = STCDGaleryFile
        
        var isSelectedMode = false
        
        func cellModel(for indexPath: IndexPath, data: STLibrary.GaleryFile?) -> CellModel {
            let image = STImageView.Image(file: data, isThumb: true)
            var videoDurationStr: String? = nil
            if let duration = data?.decryptsHeaders.file?.videoDuration, duration > 0 {
                videoDurationStr = TimeInterval(duration).timeFormat()
            }
            let isRemote = (data?.isRemote ?? false) && (data?.isSynched ?? false)
            return CellModel(image: image,
                             name: data?.file,
                             videoDuration: videoDurationStr,
                             isRemote: isRemote,
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

class STGalleryVC: STFilesSelectCollectionViewController<STGalleryVC.ViewModel> {
        
    @IBOutlet weak private var syncBarButtonItem: UIBarButtonItem!
    @IBOutlet weak private var syncView: STGallerySyncView!
    @IBOutlet weak private var selectButtonItem: UIBarButtonItem!
    
    private var selectedItem: ILibraryFile?
    private var viewModel = STGalleryVM()
    
    lazy private var accessoryView: STFilesActionTabBarAccessoryView = {
        let resilt = STFilesActionTabBarAccessoryView.loadNib()
        return resilt
    }()
    
    private lazy var pickerHelper: STPHPhotoHelper = {
        return STPHPhotoHelper(controller: self)
    }()
    
    //MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var inset = self.collectionView.contentInset
        inset.bottom = 30
        self.collectionView.contentInset = inset
        self.accessoryView.dataSource = self
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
        let vc = STFileViewerVC.create(galery: sorting, predicate: nil, file: file)
        self.selectedItem = file
        self.show(vc, sender: nil)
    }
    
    override func collectionView(didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        super.collectionView(didBeginMultipleSelectionInteractionAt: indexPath)
        UIView.animate(withDuration: 0.3) {
            self.navigationController?.navigationBar.alpha = 0.7
            self.accessoryView.alpha = 0.7
        }
    }
    
    override func collectionViewDidEndMultipleSelectionInteraction() {
        super.collectionViewDidEndMultipleSelectionInteraction()
        UIView.animate(withDuration: 0.3) {
            self.navigationController?.navigationBar.alpha = 1
            self.accessoryView.alpha = 1
        }
    }
    
    override func updateSelectedItesmCount() {
        super.updateSelectedItesmCount()
        let count = self.selectionObjectsIdentifiers.count
        let title = count == 0 ? "select_items".localized : String(format: "selected_items_count".localized, "\(count)")
        self.accessoryView.title = title
        self.accessoryView.setEnabled(isEnabled: count != .zero)
    }
    
    override func deleteSelectedItems() {
        super.deleteSelectedItems()
        let files = self.getSelectedFiles()
        let title = "delete_files_alert_title".localized
        let message = String(format: "delete_move_files_alert_message".localized, "\(files.count)")
        self.showOkCancelTextAlert(title: title, message: message, handler: { [weak self] _ in
            self?.deleteCurrentFile(files: files)
        })
    }
    
    //MARK: - User action
    
    @IBAction private func didSelectOpenImagePicker(_ sender: Any) {
        self.pickerHelper.openPicker()
    }
    
    @IBAction func didSelectSyncButton(_ sender: Any) {
        let controller = self.storyboard!.instantiateViewController(identifier: "Popover")
        controller.modalPresentationStyle = .popover
        let popController = controller.popoverPresentationController
        popController?.permittedArrowDirections = .any
        popController?.barButtonItem = self.syncBarButtonItem
        popController?.delegate = self
        self.showDetailViewController(controller, sender: nil)
    }
    
    @IBAction private func didSelecedButtonItem(_ sender: UIBarButtonItem) {
        self.setSelectionMode(isSelectionMode: !self.isSelectionMode)
    }

    //MARK: - Layout

    override func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let inset: CGFloat = 4
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 5 : layoutEnvironment.container.contentSize.width > layoutEnvironment.container.contentSize.height ? 5 : 3
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
        
    private func getSelectedFiles() -> [STLibrary.GaleryFile] {
        let selectedFileNames = [String](self.selectionObjectsIdentifiers)
        guard !selectedFileNames.isEmpty else {
            return []
        }
        let files = self.viewModel.getFiles(fileNames: selectedFileNames)
        return files
    }
    
    private func updateTabBarAccessoryView() {
        if self.dataSource.viewModel.isSelectedMode {
            (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = self.accessoryView
        } else {
            (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = nil
        }
    }

    private func didSelectShareViaStinglePhotos() {
        let files = self.getSelectedFiles()
        guard !files.isEmpty else {
            return
        }
        let storyboard = UIStoryboard(name: "Share", bundle: .main)
        let vc = (storyboard.instantiateViewController(identifier: "STSharedMembersNavVCID") as! UINavigationController)
        
        let sharedMembersVC = (vc.viewControllers.first as? STSharedMembersVC)
        sharedMembersVC?.shearedType = .files(files: files)
        
        sharedMembersVC?.complition = { [weak self] success in
            if success {
                self?.setSelectionMode(isSelectionMode: false)
            }
        }
        self.showDetailViewController(vc, sender: nil)
    }
    
    private func openActivityViewController(downloadedUrls: [URL], folderUrl: URL?) {
        let vc = STActivityViewController(activityItems: downloadedUrls, applicationActivities: nil)
        vc.popoverPresentationController?.barButtonItem = self.accessoryView.barButtonItem(for: FileAction.share)
        
        vc.complition = { [weak self] in
            if let folderUrl = folderUrl {
                self?.viewModel.removeFileSystemFolder(url: folderUrl)
            }
            self?.setSelectionMode(isSelectionMode: false)
        }
        
        self.present(vc, animated: true)
    }
    
    private func saveItemsToDevice(downloadeds: [STFilesDownloaderActivityVM.DecryptDownloadFile], folderUrl: URL?) {
        var filesSave = [(url: URL, itemType: STPHPhotoHelper.ItemType)]()
        downloadeds.forEach { file in
            let type: STPHPhotoHelper.ItemType = file.header.fileOreginalType == .image ? .photo : .video
            let url = file.url
            filesSave.append((url, type))
        }
        
        STPHPhotoHelper.save(items: filesSave) { [weak self] in
            if let folderUrl = folderUrl {
                self?.viewModel.removeFileSystemFolder(url: folderUrl)
            }
            
            DispatchQueue.main.async {
                self?.setSelectionMode(isSelectionMode: false)
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
    
    private func deleteCurrentFile(files: [STLibrary.GaleryFile]) {
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
                self?.setSelectionMode(isSelectionMode: false)
            }
        }
    }
    
    private func `import`(assets: [PHAsset]) {
        guard !assets.isEmpty else {
            return
        }
        let importer = self.viewModel.upload(assets: assets)
        let progressView = STProgressView()
        progressView.title = "importing".localized
        
        let view: UIView = self.navigationController?.view ?? self.view
        progressView.show(in: view)
        
        var importedAssets = [PHAsset]()
    
        importer.startHendler = { progress in
            let progressValue = progress.fractionCompleted
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    progressView.progress = Float(progressValue)
                    let completedUnitCount = min(progress.completedUnitCount + 1, progress.totalUnitCount)
                    progressView.subTitle = "\(completedUnitCount)/\(progress.totalUnitCount)"
                }
            }
        }
        
        importer.progressHendler = { progress in
            let progressValue = progress.fractionCompleted
                        
            if let asset = progress.importingFile?.asset {
                importedAssets.append(asset)
            }
            
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    progressView.progress = Float(progressValue)
                    let number = progress.completedUnitCount + 1
                    progressView.subTitle = "\(number)/\(progress.totalUnitCount)"
                }
            }
        }
        
        importer.complition = { [weak self] _, importableFiles in
            var assets = [PHAsset]()
            importableFiles.forEach({assets.append($0.asset)})
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.3, execute: { [weak self] in
                progressView.hide()
                guard !assets.isEmpty else {
                    return
                }
                self?.pickerHelper.deleteAssetsAfterManualImport(assets: assets)
            })
        }
    }
    
}

extension STGalleryVC: STImagePickerHelperDelegate {
    
    func pickerViewController(_ imagePickerHelper: STPHPhotoHelper, didPickAssets assets: [PHAsset], failedAssetCount: Int) {
        guard failedAssetCount > .zero else {
            self.import(assets: assets)
            return
        }
        let message = String(format: "error_import_assets".localized, "\(failedAssetCount)")
        self.showInfoAlert(title: "warning".localized, message: message, cancel: false) {
            self.import(assets: assets)
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
        let moveAlbumFilesVC = (navVC.viewControllers.first as? STMoveAlbumFilesVC)
        moveAlbumFilesVC?.moveInfo = .files(files: files)
        moveAlbumFilesVC?.complition = { [weak self] success in
            if success {
                self?.setSelectionMode(isSelectionMode: false)
            }
        }
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
        self.deleteSelectedItems()
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

extension STGalleryVC: INavigationAnimatorSourceVC {
    
    func navigationAnimator(sendnerItem animator: STNavigationAnimator.TransitioningOperation) -> Any? {
        return self.selectedItem
    }
    
    func navigationAnimator(sourceView animator: STNavigationAnimator.TransitioningOperation, sendnerItem sendner: Any?) -> INavigationAnimatorSourceView? {
        
        guard let selectedItem = sendner as? STLibrary.GaleryFile, let indexPath = self.dataSource.indexPath(at: selectedItem) else {
            return nil
        }
        
        if animator.operation == .pop {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            self.collectionView.layoutIfNeeded()
        }
        
        guard let cell = self.collectionView.cellForItem(at: indexPath) as? STGalleryCollectionViewCell else {
            return nil
        }
        
        return cell.animatorSourceView
    }
    
}
