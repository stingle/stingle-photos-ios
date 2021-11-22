//
//  STMoveAlbumFilesVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/8/21.
//

import UIKit

extension STMoveAlbumFilesVC {
    
    struct ViewModel: ICollectionDataSourceNoHeaderViewModel, IAlbumsViewModel {
                       
        typealias Cell = STMoveAlbumFilesCell
        typealias CDModel = STCDAlbum
        
        struct CellModel: IViewDataSourceCellModel {
            let identifier: Identifier = .cell
            let image: STImageView.Image?
            let placeholder: UIImage?
            let name: String?
            let title: String?
            let subTille: String?
            let isEnabled: Bool
        }
        
        
        enum Identifier: CaseIterable, IViewDataSourceItemIdentifier {
            case cell
            
            var nibName: String {
                switch self {
                case .cell:
                    return "STMoveAlbumFilesCell"

                }
            }
            
            var identifier: String {
                switch self {
                case .cell:
                    return "STMoveAlbumFilesCell"
                }
            }
        }
        
        static let imageBlankImageName = STLibrary.Album.imageBlankImageName
        
        var delegate: STAlbumsDataSourceViewModelDelegate?
        let moveInfo: MoveInfo!
        let album: STLibrary.Album?
        
        
        init(moveInfo: MoveInfo) {
            self.moveInfo = moveInfo
            switch self.moveInfo {
            case .albumFiles(let album, _):
                self.album = album
            case .files:
                self.album = nil
            default:
                self.album = nil
            }
        }
        
        func cellModel(for indexPath: IndexPath, data: STLibrary.Album) -> CellModel {
            let albumInfo = self.delegate?.viewModel(albumMedadataFor: data)
            let placeholder = UIImage(named: "ic_album")
            var image: STImageView.Image?
            
            switch data.cover {
            case ViewModel.imageBlankImageName:
                break
            default:
                if let file = albumInfo?.file {
                    image = STImageView.Image(album: data, albumFile: file, isThumb: true)
                }
            }
                    
            let name = data.albumMetadata?.name
            let isEnabled = (data.permission.allowAdd || data.isOwner) && data.albumId != self.album?.albumId
            let titles = self.createCellModelInfo(album: data, albumInfo: albumInfo)
            
            return CellModel(image: image,
                             placeholder: placeholder,
                             name: name,
                             title: titles.title,
                             subTille: titles.subTitle,
                             isEnabled: isEnabled)
            
        }
        
        private func createCellModelInfo(album: STLibrary.Album, albumInfo: (countFiles: Int, file: STLibrary.AlbumFile?, members: [STContact]?)?) -> (title: String?, subTitle: String?) {
                        
            if album.isShared {
                let contacts = albumInfo?.members ?? []
                let maxShowedMembersCount = min(3, contacts.count)
                var members = [String]()
                            
                for contact in contacts {
                    members.append(contact.email)
                    if members.count >= maxShowedMembersCount  {
                        break
                    }
                }
                let membersStr = members.joined(separator: ",")
                let moreMembersCount = contacts.count - maxShowedMembersCount
                let moreMembers: String? = moreMembersCount == 0 ? nil : String(format: "album_more_members".localized, "\(moreMembersCount)")
                return (membersStr, moreMembers)
            } else {
                let title = String(format: "items_count".localized, "\(albumInfo?.countFiles ?? 0)")
                return (title, nil)
            }
        }

    }
    
}

class STMoveAlbumFilesVC: STFilesViewController<STMoveAlbumFilesVC.ViewModel> {
    
    var moveInfo: MoveInfo!
    private let viewModel = STMoveAlbumFilesVM()

    @IBOutlet weak private var deleteFilesBgView: UIView!
    @IBOutlet weak private var mainGalleryButton: STButton!
    @IBOutlet weak private var createNewAlbum: STButton!
    @IBOutlet weak private var deleteFileLabel: UILabel!
    @IBOutlet weak private var deleteFilesSwitcher: UISwitch!
    
    private var isSuccessMoved = false
        
    var complition: ((_ success: Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViews()
    }
    
    override func configureLocalize() {
        super.configureLocalize()
        self.navigationItem.title = "add_or_move_album".localized
        self.deleteFileLabel.text = "delete_original_items_after_adding".localized
        self.mainGalleryButton.setTitle("main_gallery".localized, for: .normal)
        self.createNewAlbum.setTitle("create_new_album".localized, for: .normal)
    }
    
    override func createDataSource() -> STCollectionViewDataSource<ViewModel> {
        let viewModel = ViewModel(moveInfo: self.moveInfo)
        let dataSource = STAlbumsDataSource(collectionView: self.collectionView, predicate: nil, viewModel: viewModel)
        return dataSource
    }
    
    override func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let inset: CGFloat = 4
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 2 : 1
        let item = self.dataSource.generateCollectionLayoutItem()
        let itemSizeHeight: CGFloat = layoutEnvironment.traitCollection.isIpad() ? 120 : 80
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemSizeHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: lineCount)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        group.interItemSpacing = .fixed(inset)
                
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .zero
        section.interGroupSpacing = inset
        section.removeContentInsetsReference(safeAreaInsets: self.collectionView.window?.safeAreaInsets)
        return section
    }
    
    override func shouldAddRefreshControl() -> Bool {
        return false
    }
    
    //MARK: - Private
    
    private func moveFilesToAlbum(toAlbum: STLibrary.Album, fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile]) {
        let view: UIView = (self.navigationController?.view ?? self.view)
        STLoadingView.show(in: view)
        self.isModalInPresentation = true
        self.viewModel.moveToAlbum(fromAlbum: fromAlbum, toAlbum: toAlbum, files: files, isDeleteFiles: self.deleteFilesSwitcher.isOn) { [weak self] error in
            STLoadingView.hide(in: view)
            self?.isModalInPresentation = false
            if let error = error {
                self?.showError(error: error)
            } else {
                self?.isSuccessMoved = true
                self?.dismiss(animated: true, completion: nil)
            }
           
        }
    }
    
    private func moveFilesToAlbum(toAlbum: STLibrary.Album, files: [STLibrary.File]) {
        let view: UIView = (self.navigationController?.view ?? self.view)
        STLoadingView.show(in: view)
        self.isModalInPresentation = true
        self.viewModel.moveToAlbum(toAlbum: toAlbum, files: files, isDeleteFiles: self.deleteFilesSwitcher.isOn) { [weak self] error in
            STLoadingView.hide(in: view)
            self?.isModalInPresentation = false
            if let error = error {
                self?.showError(error: error)
            } else {
                self?.isSuccessMoved = true
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func moveFilesToAlbum(album: STLibrary.Album) {
        switch self.moveInfo {
        case .files(let files):
            self.moveFilesToAlbum(toAlbum: album, files: files)
        case .albumFiles(let fromAlbum, let files):
            self.moveFilesToAlbum(toAlbum: album, fromAlbum: fromAlbum, files: files)
        default:
            break
        }
    }
    
    ////////////////////////////////////////////////////////////////////////
    
    private func moveFilesToNewAlbum(albumName: String, files: [STLibrary.File]) {
        
    }
    
    private func moveFilesToNewAlbum(albumName: String, fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile]) {
        let view: UIView = (self.navigationController?.view ?? self.view)
        STLoadingView.show(in: view)
        self.isModalInPresentation = true
        self.viewModel.createAlbum(name: albumName, fromAlbum: fromAlbum, files: files, isDeleteFiles: self.deleteFilesSwitcher.isOn) { [weak self] error in
            STLoadingView.hide(in: view)
            self?.isModalInPresentation = false
            if let error = error {
                self?.showError(error: error)
            } else {
                self?.isSuccessMoved = true
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func moveFilesToNewAlbum(albumName: String) {
        switch self.moveInfo {
        case .albumFiles(let album, let files):
            self.moveFilesToNewAlbum(albumName: albumName, fromAlbum: album, files: files)
        case .files:
           break
        default:
            break
        }
    }
    
    private func moveFilesToNewAlbum() {
        let view: UIView = (self.navigationController?.view ?? self.view)
        self.showAddAlbumAlert { [weak self] name in
            STLoadingView.show(in: view)
            self?.isModalInPresentation = true
            self?.viewModel.createAlbum(name: name, result: { error in
                STLoadingView.hide(in: view)
                self?.isModalInPresentation = false
                if let error = error {
                    self?.showError(error: error)
                }
            })
        }
    }
    
    ////////////////////////////////////////////////////////////////////////
    
    private func moveFilesToGallery(fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile]) {
        let view: UIView = (self.navigationController?.view ?? self.view)
        STLoadingView.show(in: view)
        self.isModalInPresentation = true
        self.viewModel.moveFilesToGallery(fromAlbum: fromAlbum, files: files, isDeleteFiles: self.deleteFilesSwitcher.isOn) { [weak self] error in
            STLoadingView.hide(in: view)
            self?.isModalInPresentation = false
            if let error = error {
                self?.showError(error: error)
            } else {
                self?.isSuccessMoved = true
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func moveFilesToGallery() {
        switch self.moveInfo {
        case .albumFiles(let album, let files):
            self.moveFilesToGallery(fromAlbum: album, files: files)
        default:
            break
        }
    }
    
    ////////////////////////////////////////////////////////////////////////
        
    private func configureViews() {
        switch self.moveInfo {
        case .albumFiles(let album, _):
            self.mainGalleryButton.isHidden = false
            self.deleteFilesBgView.isHidden = !album.isOwner
        case .files:
            self.mainGalleryButton.isHidden = true
            self.deleteFilesBgView.isHidden = false
        default:
            break
        }
        self.deleteFilesSwitcher.isOn = self.viewModel.isDeleteFilesLastValue
    }
    
    private func showAddAlbumAlert(okAction: @escaping ((String) -> Void)) {
        let title = "create_album_title".localized
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "album_name".localized
        }
        let ok = UIAlertAction(title: "ok".localized, style: .default) { (_) in
            okAction(alert.textFields?.first?.text ?? "")
        }
        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - User action
    
    @IBAction private func didCreateNewAlbumButton(_ sender: Any) {
        self.moveFilesToNewAlbum()
    }
    
    @IBAction private func didSelecctMainGalleryButton(_ sender: Any) {
        self.moveFilesToGallery()
    }
    
    @IBAction private func didSelectCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        self.complition?(self.isSuccessMoved)
    }
    
}

extension STMoveAlbumFilesVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let album = self.dataSource.object(at: indexPath) else {
            return
        }
        self.moveFilesToAlbum(album: album)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let album = self.dataSource.object(at: indexPath)
        return album?.albumId != self.dataSource.viewModel.album?.albumId && (album?.permission.allowAdd ?? false || album?.isOwner ?? false)
    }
    
}

extension STMoveAlbumFilesVC {
    
    enum MoveInfo {
        case files(files: [STLibrary.File])
        case albumFiles(album: STLibrary.Album, files: [STLibrary.AlbumFile])
    }
    
}
