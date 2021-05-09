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
        
        static let imageBlankImageName = "__b__"
        
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
            let isEnabled = data.permission.allowAdd && data.albumId != self.album?.albumId
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViews()
    }
    
    override func configureLocalize() {
        super.configureLocalize()
        self.navigationItem.title = "add_or_move_album".localized
        self.deleteFileLabel.text = "delete_original_items_after_adding".localized
        self.mainGalleryButton.setTitle("main_gallry".localized, for: .normal)
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
    
    private func moveToAlbum(album: STLibrary.Album) {
        
        switch self.moveInfo {
       
        case .files(let files):
            
            break
            
        case .albumFiles(let fromAlbum, let files):
            let view: UIView = (self.navigationController?.view ?? self.view)
            STLoadingView.show(in: view)
            self.viewModel.moveToAlbum(fromAlbum: fromAlbum, toAlbum: album, files: files, isDeleteFiles: self.deleteFilesSwitcher.isOn) { [weak self] error in
                STLoadingView.hide(in: view)
                if let error = error {
                    self?.showError(error: error)
                } else {
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        default:
            break
        }
        
    }
    
    private func moveToNewAlbum() {
        
        
    }
    
    private func moveToGallery() {
        
        
    }
        
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
    
    //MARK: - User action
    
    @IBAction private func didCreateNewAlbumButton(_ sender: Any) {
        self.moveToNewAlbum()
    }
    
    @IBAction private func didSelecctMainGalleryButton(_ sender: Any) {
        self.moveToGallery()
    }
    
    @IBAction private func didSelectCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension STMoveAlbumFilesVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let album = self.dataSource.object(at: indexPath) else {
            return
        }
        self.moveToAlbum(album: album)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let album = self.dataSource.object(at: indexPath)
        return album?.albumId != self.dataSource.viewModel.album?.albumId && album?.permission.allowAdd ?? false
    }
    
}

extension STMoveAlbumFilesVC {
    
    enum MoveInfo {
        case files(files: [STLibrary.File])
        case albumFiles(album: STLibrary.Album, files: [STLibrary.AlbumFile])
    }
    
}
