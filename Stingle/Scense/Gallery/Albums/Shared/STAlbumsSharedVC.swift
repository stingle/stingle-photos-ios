//
//  STAlbumsSharedVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/26/21.
//

import UIKit

extension STAlbumsSharedVC {
    
    struct ViewModel: ICollectionDataSourceNoHeaderViewModel, IAlbumsViewModel {
        
        typealias Cell = STAlbumsSharedCollectionViewCell
        typealias CDModel = STCDAlbum
        
        static let imageBlankImageName = STLibrary.Album.imageBlankImageName
        weak var delegate: STAlbumsDataSourceViewModelDelegate?
        
        enum Identifier: CaseIterable, IViewDataSourceItemIdentifier {
            case album
            
            var nibName: String {
                switch self {
                case .album:
                    return "STAlbumsSharedCollectionViewCell"
                }
            }
            
            var identifier: String {
                switch self {
                case .album:
                    return "STAlbumsSharedCollectionViewCellID"
                }
            }
        }
        
        struct HeaderModel {
            let text: String?
        }
        
        struct CellModel: IViewDataSourceCellModel {
            let identifier: Identifier = .album
            let image: STImageView.Image?
            let placeholder: UIImage?
            let title: String?
            let members: String?
            let moreMembers: String?
            let iconIsOwner: UIImage?
        }
                
        func cellModel(for indexPath: IndexPath, data: STLibrary.Album?) -> CellModel {
            let metadata = self.delegate?.viewModel(albumMedadataFor: data)
            let placeholder = UIImage(named: "ic_album")
            var image: STImageView.Image?
            
            switch data?.cover {
            case ViewModel.imageBlankImageName:
                break
            default:
                if let file = metadata?.file {
                    image = STImageView.Image(album: data, albumFile: file, isThumb: true)
                }
            }
            let title = data?.albumMetadata?.name
            let contacts = metadata?.members ?? []
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
            
            let iconIsOwner = (data?.isOwner ?? true) ? UIImage(named: "ic_alnum_shared_owner") : UIImage(named: "ic_alnum_shared_no_owner")
            
            return CellModel(image: image, placeholder: placeholder, title: title, members: membersStr, moreMembers: moreMembers, iconIsOwner: iconIsOwner)
        }
    }
    
}

class STAlbumsSharedVC: STFilesViewController<STAlbumsSharedVC.ViewModel> {
        
    private let viewModel = STAlbumsSharedVM()
    private let segueIdentifierAlbumFiles = "AlbumFiles"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView.reloadData()
    }
    
    override func configureLocalize() {
        self.navigationItem.title = "sharing".localized
        self.navigationController?.tabBarItem.title = "sharing".localized
        
        self.emptyDataTitleLabel?.text = "empy_shared_albums_title".localized
        self.emptyDataSubTitleLabel?.text = "empy_shared_albums_message".localized
    }
    
    override func createDataSource() -> STCollectionViewDataSource<STAlbumsSharedVC.ViewModel> {
        let viewModel = ViewModel()
        let predicate = NSPredicate(format: "isHidden == %i || isShared == %i", true, true)
        let dataSource = STAlbumsDataSource(collectionView: self.collectionView, predicate: predicate, viewModel: viewModel)
        return dataSource
    }

    override func refreshControlDidRefresh() {
        self.viewModel.sync()
    }
 
    override func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let inset: CGFloat = 4
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 2 : 1
        let item = self.dataSource.generateCollectionLayoutItem()
        let itemSizeHeight: CGFloat = 120
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.segueIdentifierAlbumFiles, let albumFilesVC = segue.destination as? STAlbumFilesVC, let album = sender as? STLibrary.Album {
            albumFilesVC.album = album
        }
    }
    
}

extension STAlbumsSharedVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let album = self.dataSource.object(at: indexPath) else {
            return
        }
        self.performSegue(withIdentifier: self.segueIdentifierAlbumFiles, sender: album)
    }
    
}
