//
//  STAlbumFilesVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/19/21.
//

import UIKit

extension STAlbumFilesVC {
    
    struct ViewModel: ICollectionDataSourceViewModel {
                              
        typealias Header = STAlbumFilesHeaderView
        typealias Cell = STAlbumFilesCollectionViewCell
        typealias CDModel = STCDAlbumFile
        
        let album: STLibrary.Album
        var isSelectedMode = false
        var selectedFileNames = Set<String>()
        
        init(album: STLibrary.Album) {
            self.album = album
        }
        
        func cellModel(for indexPath: IndexPath, data: STLibrary.AlbumFile) -> CellModel {
            let image = STImageView.Image(album: self.album, albumFile: data, isThumb: true)
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

class STAlbumFilesVC: STFilesViewController<STAlbumFilesVC.ViewModel> {
    
    @IBOutlet weak private var addItemButton: UIButton!
    @IBOutlet weak private var selectButtonItem: UIBarButtonItem!
    @IBOutlet weak private var albumSettingsButtonItem: UIBarButtonItem!
    @IBOutlet weak private var moreBarButtonItem: UIBarButtonItem!
    
    private var viewModel: STAlbumFilesVM!
    var album: STLibrary.Album!
    
    lazy var accessoryView: STAlbumFilesTabBarAccessoryView = {
        let resilt = STAlbumFilesTabBarAccessoryView.loadNib()
        return resilt
    }()
    
    override func viewDidLoad() {
        self.viewModel = STAlbumFilesVM(album: self.album)
        self.viewModel.delegate = self
        super.viewDidLoad()
        self.configureAlbumActionView()
        self.accessoryView.delegate = self
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
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 5 : 3
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
    
    //MARK: - UserAction
    
    @IBAction func didSelectMoreButton(_ sender: UIBarButtonItem) {
        let fileNames = self.dataSource.viewModel.isSelectedMode ? [String](self.dataSource.viewModel.selectedFileNames) : nil
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
    
    @IBAction func didSelectAlbumSettingsButton(_ sender: UIBarButtonItem) {
        if !self.album.isShared {
            let storyboard = UIStoryboard(name: "Shear", bundle: .main)
            let vc = (storyboard.instantiateViewController(identifier: "STSharedMembersVCID") as! UINavigationController)
            (vc.viewControllers.first as? STSharedMembersVC)?.shearedType = .album(album: self.album)
            self.showDetailViewController(vc, sender: nil)
        }
    }
    
    @IBAction func didSelectAddButton(_ sender: Any) {
        
    }
    
    @IBAction private func didSelectSelecedButtonItem(_ sender: UIBarButtonItem) {
        self.dataSource.viewModel.selectedFileNames.removeAll()
        self.dataSource.viewModel.isSelectedMode = !self.dataSource.viewModel.isSelectedMode
        self.updateTabBarAccessoryView()
        self.selectButtonItem.title = self.dataSource.viewModel.isSelectedMode ? "cancel".localized : "select".localized
        self.collectionView.reloadData()
        self.updateSelectedItesmCount()
    }
    
    //MARK: - Private
    
    private func didSelectShitAction(action: AlbumAction) {
        
        let loadingView: UIView =  self.navigationController?.view ?? self.view
        
        func didResiveResult(error: IError?) {
            STLoadingView.hide(in: loadingView)
            if let error = error {
                self.showError(error: error)
            }
        }
        
        switch action {
        case .rename:
            let placeholder = "album_name".localized
            let title = "rename_album".localized
            self.showOkCancelAlert(title: title, message: nil, textFieldText: self.album.albumMetadata?.name, textFieldPlaceholder: placeholder) { [weak self] newName in
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
            self.showOkCancelAlert(title: title, message: message) { [weak self] _ in
                STLoadingView.show(in: loadingView)
                self?.viewModel.delete { error in
                    didResiveResult(error: error)
                }
            }
        case .leave:
            STLoadingView.show(in: loadingView)
            self.viewModel.leave { error in
                didResiveResult(error: error)
            }
        case .setCover:
            STLoadingView.show(in: loadingView)
            let fileName = self.dataSource.viewModel.selectedFileNames.first ?? ""
            self.viewModel.setCover(fileName: fileName) { error in
                didResiveResult(error: error)
            }
        case .downloadSelection:
            break
        }
        
    }
    
    private func updateSelectedItesmCount() {
        let count = self.dataSource.viewModel.selectedFileNames.count
        let title = count == 0 ? "select_items".localized : String(format: "selected_items_count".localized, "\(count)")
        self.accessoryView.titleLabel.text = title
        self.accessoryView.setEnabled(isEnabled: count != .zero)
    }
    
    private func updateTabBarAccessoryView() {
        if self.dataSource.viewModel.isSelectedMode {
            (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = self.accessoryView
        } else {
            (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = nil
        }
    }

    private func configureAlbumActionView() {
        self.accessoryView.sharButton.isHidden = !self.album.permission.allowShare
        self.accessoryView.copyButton.isHidden = !self.album.permission.allowCopy
        self.accessoryView.downloadButton.isHidden = !self.album.permission.allowCopy
        self.addItemButton.isHidden = !self.album.permission.allowAdd
        self.accessoryView.trashButton.isHidden = !self.album.isOwner
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
    
    private func showOkCancelAlert(title: String?, message: String?, textFieldText: String? = nil, textFieldPlaceholder: String? = nil, handler: @escaping ((String?) -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "ok".localized, style: .default) {_ in
            handler(alert.textFields?.first?.text)
        }
        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        
        if let textFieldPlaceholder = textFieldPlaceholder {
            alert.addTextField { (textField) in
                textField.text = textFieldText
                textField.placeholder = textFieldPlaceholder
            }
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func deleteSelectedFiles() {
        STLoadingView.show(in: self.view)
        let files: [String] = [String](self.dataSource.viewModel.selectedFileNames)
        self.viewModel.deleteFiles(files: files) { [weak self] error in
            guard let weakSelf = self else{
                return
            }
            STLoadingView.hide(in: weakSelf.view)
            if let error = error {
                weakSelf.showError(error: error)
            } else {
                weakSelf.dataSource.viewModel.selectedFileNames.removeAll()
                weakSelf.updateSelectedItesmCount()
            }
        }
    }
    
    
    
}

extension STAlbumFilesVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.dataSource.viewModel.isSelectedMode {
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
            let cell = (collectionView.cellForItem(at: indexPath) as? STAlbumFilesCollectionViewCell)
            cell?.setSelected(isSelected: isSelected)
            self.updateSelectedItesmCount()
        }
        
    }
    
}

extension STAlbumFilesVC: STAlbumFilesTabBarAccessoryViewDelegate {
    
    func albumFilesTabBarAccessory(view: STAlbumFilesTabBarAccessoryView, didSelectShareButton sendner: UIButton) {
        let selectedFileNames = [String](self.dataSource.viewModel.selectedFileNames)
        guard !selectedFileNames.isEmpty else {
            return
        }
        let files = self.viewModel.getFiles(fileNames: selectedFileNames)
        let storyboard = UIStoryboard(name: "Shear", bundle: .main)
        let vc = (storyboard.instantiateViewController(identifier: "STSharedMembersVCID") as! UINavigationController)
        (vc.viewControllers.first as? STSharedMembersVC)?.shearedType = .albumFiles(album: self.album, files: files)
        self.showDetailViewController(vc, sender: nil)
    }
    
    func albumFilesTabBarAccessory(view: STAlbumFilesTabBarAccessoryView, didSelectCopyButton sendner: UIButton) {
        let selectedFileNames = [String](self.dataSource.viewModel.selectedFileNames)
        let navVC = self.storyboard?.instantiateViewController(identifier: "goToMoveAlbumFiles") as! UINavigationController
        (navVC.viewControllers.first as? STMoveAlbumFilesVC)?.moveInfo = .albumFiles(album: self.album, files: self.viewModel.getFiles(fileNames: selectedFileNames))
        self.showDetailViewController(navVC, sender: nil)
    }
    
    func albumFilesTabBarAccessory(view: STAlbumFilesTabBarAccessoryView, didSelectDownloadButton sendner: UIButton) {
        
    }
    
    func albumFilesTabBarAccessory(view: STAlbumFilesTabBarAccessoryView, didSelectTrashButton sendner: UIButton) {
        let count = self.dataSource.viewModel.selectedFileNames.count
        let title = "delete_album_files_alert_title".localized
        let message = String(format: "delete_album_files_alert_message".localized, "\(count)")
        
        self.showOkCancelAlert(title: title, message: message) { [weak self] _ in
            self?.deleteSelectedFiles()
        }
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
    
}
