//
//  STFileViewerVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import UIKit

protocol IFileViewer: UIViewController {
    
    static func create(file: STLibrary.File, fileIndex: Int) -> IFileViewer
    var file: STLibrary.File { get }
    var fileIndex: Int { get set }
    var fileViewerDelegate: IFileViewerDelegate? { get set }
    
    var animatorSourceView: INavigationAnimatorSourceView? { get }
    
    func fileViewer(didChangeViewerStyle fileViewer: STFileViewerVC, isFullScreen: Bool)
    func fileViewer(pauseContent fileViewer: STFileViewerVC)
    
}

protocol IFileViewerDelegate: AnyObject {
    var isFullScreenMode: Bool { get }
    func photoViewer(startFullScreen viewer: STPhotoViewerVC)
}

class STFileViewerVC: UIViewController {
    
    private var viewModel: IFileViewerVM!
    private var currentIndex: Int?
    private var pageViewController: UIPageViewController!
    private var viewControllers = STObserverEvents<IFileViewer>()
    private var viewerStyle: ViewerStyle = .white
    private weak var titleView: STFileViewerNavigationTitleView?
    private var initialFile: STLibrary.File?
    
    @IBOutlet weak private var toolBar: UIView!
        
    lazy private var accessoryView: STFilesActionTabBarAccessoryView = {
        let resilt = STFilesActionTabBarAccessoryView.loadNib()
        return resilt
    }()
    
    private lazy var pickerHelper: STPHPhotoHelper = {
        return STPHPhotoHelper(controller: nil)
    }()
    
    private var currentFile: STLibrary.File? {
        guard let currentIndex = self.currentIndex, let file = self.viewModel.object(at: currentIndex) else {
            return nil
        }
        return file
    }
    
    private var currentFileViewer: IFileViewer? {
        guard let currentIndex = self.currentIndex, let vc = self.viewControllers.objects.first(where: { $0.fileIndex == currentIndex }) else {
            return nil
        }
        return vc
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return self.currentFileViewer?.prefersHomeIndicatorAutoHidden ?? super.prefersHomeIndicatorAutoHidden
    }
            
    override func viewDidLoad() {
        super.viewDidLoad()
        if let initialFile = self.initialFile, self.currentIndex == nil {
            self.currentIndex = self.viewModel.index(at: initialFile)
        }
        self.accessoryView.dataSource = self
        self.viewerStyle = .balck
        self.changeViewerStyle()
        self.setupTavigationTitle()
        self.setupPageViewController()
        self.setupTapGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureAccessoryView()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = nil
        if self.viewerStyle == .balck {
            self.changeViewerStyle()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pageViewController" {
            self.pageViewController = segue.destination as? UIPageViewController
            self.pageViewController.dataSource = self
            for v in pageViewController.view.subviews {
                if let scrollView = v as? UIScrollView {
                    scrollView.delegate = self
                    break
                }
            }
        }
    }
    
    //MARK: - User action
    
    @IBAction private func didSelectMoreButton(_ sender: UIBarButtonItem) {
        
        guard let currentFile = self.currentFile else {
            return
        }
        self.currentFileViewer?.fileViewer(pauseContent: self)
        
        let actions = self.viewModel.getMorAction(for: currentFile)
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actions.forEach { action in
            let action = UIAlertAction(title: action.localized, style: .default) { [weak self] _ in
                self?.didSelectMore(action: action, file: currentFile)
            }
            alert.addAction(action)
        }
        
        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(cancel)
            
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        self.showDetailViewController(alert, sender: nil)
    }
    
    @objc private func didSelectBackground(tap: UIGestureRecognizer) {
        UIView.animate(withDuration: 0.15) {
            self.changeViewerStyle()
        }
    }
    
    private func didSelectMore(action: MoreAction, file: STLibrary.File) {
        self.viewModel.selectMore(action: action, file: file)
    }
        
    //MARK: - Private methods
        
    private func configureAccessoryView() {
        if let tabBarController = self.tabBarController {
            self.toolBar.isHidden = true
            (tabBarController.tabBar as? STTabBar)?.accessoryView = self.accessoryView
        } else {
            self.toolBar.isHidden = false
            self.toolBar.addSubviewFullContent(view: self.accessoryView)
        }
    }
        
    private func setupTavigationTitle() {
        let titleView = STFileViewerNavigationTitleView()
        self.titleView = titleView
        self.navigationItem.titleView = titleView
    }
    
    private func setupPageViewController() {
        guard let viewController = self.viewController(for: self.currentIndex) else {
            return
        }
        self.pageViewController.setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
        self.didChangeFileViewer()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didSelectBackground(tap:)))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
    }
    
    private func viewController(for index: Int?) -> IFileViewer? {
        guard let index = index, let file = self.viewModel.object(at: index), let fileType = file.decryptsHeaders.file?.fileOreginalType  else {
            return nil
        }
        switch fileType {
        case .video:
            let vc = STVideoViewerVC.create(file: file, fileIndex: index)
            vc.fileViewerDelegate = self
            self.viewControllers.addObject(vc)
            return vc
        case .image:
            let vc = STPhotoViewerVC.create(file: file, fileIndex: index)
            vc.fileViewerDelegate = self
            self.viewControllers.addObject(vc)
            return vc
        }
    }
    
    private func changeViewerStyle() {
        switch self.viewerStyle {
        case .white:
            self.view.backgroundColor = .black
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            self.toolBar.alpha = .zero
            self.tabBarController?.tabBar.alpha = .zero
            self.viewerStyle = .balck
        case .balck:
            self.view.backgroundColor = .appBackground
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            self.toolBar.alpha = 1
            self.tabBarController?.tabBar.alpha = 1
            self.viewerStyle = .white
        }
        
        self.splitMenuViewController?.setNeedsStatusBarAppearanceUpdate()
        self.viewControllers.forEach({ $0.fileViewer(didChangeViewerStyle: self, isFullScreen: self.viewerStyle == .balck)})
    }
    
    private func didChangeFileViewer() {
        guard let currentIndex = self.currentIndex, let file = self.viewModel.object(at: currentIndex) else {
            self.titleView?.title = nil
            self.titleView?.subTitle = nil
            self.accessoryView.reloadData()
            return
        }
        let dateManager = STDateManager.shared
        self.titleView?.title = dateManager.dateToString(date: file.dateCreated, withFormate: .mmm_dd_yyyy)
        self.titleView?.subTitle = dateManager.dateToString(date: file.dateCreated, withFormate: .HH_mm)
        self.accessoryView.reloadData()
    }
    
    private func deleteCurrentFile() {
        guard let file = self.currentFile else {
            return
        }
        STLoadingView.show(in: self.view)
        self.viewModel.deleteFile(file: file) { [weak self] error in
            guard let weakSelf = self else{
                return
            }
            STLoadingView.hide(in: weakSelf.view)
            if let error = error {
                weakSelf.showError(error: error)
            }
        }
    }
    
    private func openDownloadController(action: FilesDownloadDecryptAction) {
        guard let file = self.currentFile else {
            return
        }
        let shearing = STFilesDownloaderActivityVC.DownloadFiles.files(files: [file])
        
        STFilesDownloaderActivityVC.showActivity(downloadingFiles: shearing, controller: self.tabBarController ?? self, delegate: self, userInfo: action)
    }
    
    private func openActivityViewController(downloadedUrls: [URL], folderUrl: URL?) {
        let vc = UIActivityViewController(activityItems: downloadedUrls, applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = self.accessoryView.barButtonItem(for: ActionType.share)
        vc.completionWithItemsHandler = { [weak self] (type,completed,items,error) in
            if let folderUrl = folderUrl {
                self?.viewModel.removeFileSystemFolder(url: folderUrl)
            }
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
        }
    }
    
    private func didSelectShareViaStinglePhotos() {
        guard let file = self.currentFile else {
            return
        }
        let storyboard = UIStoryboard(name: "Shear", bundle: .main)
        let vc = (storyboard.instantiateViewController(identifier: "STSharedMembersNavVCID") as! UINavigationController)
        (vc.viewControllers.first as? STSharedMembersVC)?.shearedType = .files(files: [file])
        self.showDetailViewController(vc, sender: nil)
    }
    
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

    private func didSelectEdit() {
        guard let file = self.currentFile else {
            return
        }
        let viewModel = self.viewModel.editVM(for: file)
        let vc = STFileEditVC.create(viewModel: viewModel)
        vc.delegate = self
        self.present(vc, animated: true)
    }

}

extension STFileViewerVC {

    static func create(galery sortDescriptorsKeys: [STDataBase.DataSource<STCDFile>.Sort], predicate: NSPredicate?, file: STLibrary.File) -> STFileViewerVC {
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: Self = storyboard.instantiateViewController(identifier: "STFileViewerVCID")
        let viewModel = STGaleryFileViewerVM(sortDescriptorsKeys: sortDescriptorsKeys, predicate: predicate)
        vc.viewModel = viewModel
        vc.initialFile = file
        vc.viewModel.delegate = vc
        return vc
    }
    
    static func create(album: STLibrary.Album, file: STLibrary.AlbumFile, sortDescriptorsKeys: [STDataBase.DataSource<STCDAlbumFile>.Sort]) -> STFileViewerVC {
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: Self = storyboard.instantiateViewController(identifier: "STFileViewerVCID")
        let viewModel = STAlbumFileViewerVM(album: album, sortDescriptorsKeys: sortDescriptorsKeys)
        vc.viewModel = viewModel
        vc.initialFile = file
        vc.viewModel.delegate = vc
        return vc
    }
    
    static func create(trash file: STLibrary.TrashFile, sortDescriptorsKeys: [STDataBase.DataSource<STCDTrashFile>.Sort]) -> STFileViewerVC {
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: Self = storyboard.instantiateViewController(identifier: "STFileViewerVCID")
        let viewModel = STTrashFileViewerVM(sortDescriptorsKeys: sortDescriptorsKeys)
        vc.viewModel = viewModel
        vc.initialFile = file
        vc.viewModel.delegate = vc
        return vc
    }
    
}

extension STFileViewerVC: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension STFileViewerVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard scrollView.isDragging, let currentIndex = self.currentIndex, let vc = self.viewControllers.objects.first(where: { $0.fileIndex == currentIndex }) else {
            return
        }
        let org = self.view.convert(vc.view.frame.origin, from: vc.view.superview)
        let pageWidth = scrollView.frame.size.width
        let fractionalPage = (-org.x + CGFloat(currentIndex) * pageWidth) / pageWidth
        let page = lround(Double(fractionalPage))
                
        if self.currentIndex != page {
            self.currentIndex = page
            self.didChangeFileViewer()
        }
         
    }
    
}

extension STFileViewerVC {
    
    private func didSelectShare(sendner: UIBarButtonItem) {
        self.currentFileViewer?.fileViewer(pauseContent: self)
        self.showShareFileActionSheet(sender: sendner)
    }
    
    func didSelectMove(sendner: UIBarButtonItem) {
        self.currentFileViewer?.fileViewer(pauseContent: self)
        guard let file = self.currentFile else {
            return
        }
        let navVC = self.storyboard?.instantiateViewController(identifier: "goToMoveAlbumFiles") as! UINavigationController
        (navVC.viewControllers.first as? STMoveAlbumFilesVC)?.moveInfo = self.viewModel.moveInfo(for: file)
        self.showDetailViewController(navVC, sender: nil)
    }
    
    func didSelectSaveToDevice(sendner: UIBarButtonItem) {
        let title = "alert_save_to_device_library_title".localized
        let message = "alert_save_file_to_device_library_message".localized
        self.showInfoAlert(title: title, message: message, cancel: true) { [weak self] in
            self?.openDownloadController(action: .saveDevicePhotos)
        }
    }
    
    func didSelectTrash(sendner: UIBarButtonItem) {
        guard let file = self.currentFile else {
            return
        }
        self.currentFileViewer?.fileViewer(pauseContent: self)
        let title = self.viewModel.getDeleteFileMessage(file: file)
        self.showOkCancelTextAlert(title: title, message: nil, handler: { [weak self] _ in
            self?.deleteCurrentFile()
        })
    }
    
}

extension STFileViewerVC: STFilesActionTabBarAccessoryViewDataSource {
    
    
    func accessoryView(actions accessoryView: STFilesActionTabBarAccessoryView) -> [STFilesActionTabBarAccessoryView.ActionItem] {
        
        guard let currentFile = self.currentFile else {
            return []
        }
        
        let actions = self.viewModel.getAction(for: currentFile)
        var result = [STFilesActionTabBarAccessoryView.ActionItem]()
        
        actions.forEach { type in
            switch type {
            case .share:
                let share = STFilesActionTabBarAccessoryView.ActionItem.share(identifier: type) { [weak self] _ , buttonItem  in
                    self?.didSelectShare(sendner: buttonItem)
                }
                result.append(share)
            case .move:
                let move = STFilesActionTabBarAccessoryView.ActionItem.move(identifier: type) { [weak self] _, buttonItem in
                    self?.didSelectMove(sendner: buttonItem)
                }
                result.append(move)
            case .saveToDevice:
                let saveToDevice = STFilesActionTabBarAccessoryView.ActionItem.saveToDevice(identifier: type) { [weak self] _, buttonItem in
                    self?.didSelectSaveToDevice(sendner: buttonItem)
                }
                result.append(saveToDevice)
            case .trash:
                let trash = STFilesActionTabBarAccessoryView.ActionItem.trash(identifier: type) { [weak self] _, buttonItem in
                    self?.didSelectTrash(sendner: buttonItem)
                }
                result.append(trash)
            case .edit:
                let edit = STFilesActionTabBarAccessoryView.ActionItem.edit(identifier: type) { [weak self] _, _ in
                    self?.didSelectEdit()
                }
                result.append(edit)
            }
        }

        return result
        
    }
    
}

extension STFileViewerVC: STFileEditVCDelegate {

    func fileEdit(didSelectCancel vc: STFileEditVC) {
        vc.dismiss(animated: true)
    }

    func fileEdit(didEditFile vc: STFileEditVC, viewModel: IFileEditVM) {
        vc.dismiss(animated: true)
    }

}

extension STFileViewerVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let fileViewer = viewController as? IFileViewer else {
            return nil
        }
        let beforeIndex = fileViewer.fileIndex - 1
        return self.viewController(for: beforeIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let fileViewer = viewController as? IFileViewer else {
            return nil
        }
        let afterIndex = fileViewer.fileIndex + 1
        return self.viewController(for: afterIndex)
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return self.viewModel.countOfItems
    }
        
}

extension STFileViewerVC: STFileViewerVMDelegate {
    
    func fileViewerVM(didUpdateedData fileViewerVM: IFileViewerVM) {
        
        guard self.isViewLoaded else {
            return
        }
        
        if let initialFile = self.initialFile, self.currentIndex == nil {
            self.currentIndex = self.viewModel.index(at: initialFile)
        }

        guard let currentIndex = self.currentIndex else {
            self.navigationController?.popViewController(animated: true)
            return
        }

        guard let file = self.currentFileViewer?.file else {
            return
        }
        
        let index = self.viewModel.index(at: file)
        
        if index == nil || index == NSNotFound {
            if currentIndex < self.viewModel.countOfItems, let vc = self.viewController(for: currentIndex)  {
                self.pageViewController.setViewControllers([vc], direction: .forward, animated: true, completion: nil)
            } else if currentIndex - 1 < self.viewModel.countOfItems, let vc = self.viewController(for: currentIndex - 1) {
                self.currentIndex = currentIndex - 1
                self.pageViewController.setViewControllers([vc], direction: .reverse, animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else if let index = index, let currentFileViewer = self.currentFileViewer {
            currentFileViewer.fileIndex = index
            if self.pageViewController.viewControllers?.count != 1 {
                self.pageViewController.setViewControllers([currentFileViewer], direction: .forward, animated: false, completion: nil)
            }
        }
    }
    
}

extension STFileViewerVC: STFilesDownloaderActivityVCDelegate {
    
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

extension STFileViewerVC: INavigationAnimatorDestinationVC {
    
    func navigationAnimator(sendnerItem animator: STNavigationAnimator.TransitioningOperation) -> Any? {
        return self.currentFile
    }
    
    func navigationAnimator(sourceView animator: STNavigationAnimator.TransitioningOperation, sendnerItem: Any?) -> INavigationAnimatorSourceView? {
        return self.currentFileViewer?.animatorSourceView
    }
    
}

extension STFileViewerVC: IFileViewerDelegate {
   
    func photoViewer(startFullScreen viewer: STPhotoViewerVC) {
        guard self.viewerStyle == .white else {
            return
        }
        self.changeViewerStyle()
    }
    
    var isFullScreenMode: Bool {
        return self.viewerStyle == .balck
    }
    
}

extension STFileViewerVC {
    
    enum ViewerStyle {
        case white
        case balck
    }
    
    enum FilesDownloadDecryptAction {
        case share
        case saveDevicePhotos
    }
    
    enum ActionType: StringPointer, CaseIterable {
        
        case share
        case move
        case saveToDevice
        case trash
        case edit
        
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
            case .edit:
                return "edit"
            }
        }
        
    }
    
    enum MoreAction: StringPointer, CaseIterable {
        
        case download
        case setAlbumCover
       
        var stringValue: String {
            switch self {
            case .download:
                return "download"
            case .setAlbumCover:
                return "setAlbumCover"
            }
        }
        
        var localized: String {
            switch self {
            case .download:
                return "download_file".localized
            case .setAlbumCover:
                return "set_album_cover".localized
            }
        }
        
    }
    
    
    
}
