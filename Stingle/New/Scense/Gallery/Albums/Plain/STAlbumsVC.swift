//
//  STAlbumsVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import UIKit

extension STAlbumsVC {
    
    struct ViewModel: ICollectionDataSourceNoHeaderViewModel, IAlbumsViewModel {
        
        typealias Cell = STAlbumsCollectionViewCell
        typealias CDModel = STCDAlbum
        
        static let imageBlankImageName = "__b__"
        weak var delegate: STAlbumsDataSourceViewModelDelegate?
        
        enum Identifier: CaseIterable, IViewDataSourceItemIdentifier {
            case album
            
            var nibName: String {
                switch self {
                case .album:
                    return "STAlbumsCollectionViewCell"
                }
            }
            
            var identifier: String {
                switch self {
                case .album:
                    return "STAlbumsCollectionViewCellID"
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
            let subTille: String?
        }
                
        func cellModel(for indexPath: IndexPath, data: STLibrary.Album) -> CellModel {
            let metadata = self.delegate?.viewModel(viewModel: self, albumMedadataFor: data)
            let placeholder = UIImage(named: "ic_album")
            var image: STImageView.Image?
            
            switch data.cover {
            case ViewModel.imageBlankImageName:
                break
            default:
                if let file = metadata?.file {
                    image = STImageView.Image(album: data, albumFile: file, isThumb: true)
                }
            }
            let title = data.albumMetadata?.name
            let subTille = String(format: "items_count".localized, "\(metadata?.countFiles ?? 0)")
            return CellModel(image: image, placeholder: placeholder, title: title, subTille: subTille)
        }
    }
    
}

class STAlbumsVC: STFilesViewController<STAlbumsVC.ViewModel> {
        
    private let viewModel = STAlbumsVM()
    private let segueIdentifierAlbumFiles = "AlbumFiles"
    
    override func configureLocalize() {
        self.navigationItem.title = "albums".localized
        self.navigationController?.tabBarItem.title = "albums".localized
        
        self.emptyDataTitleLabel?.text = "empy_albums_title".localized
        self.emptyDataSubTitleLabel?.text = "empy_albums_message".localized        
    }
    
    override func createDataSource() -> STCollectionViewDataSource<STAlbumsVC.ViewModel> {
        let viewModel = ViewModel()
        let dataSource = STAlbumsDataSource(collectionView: self.collectionView, isShared: false, viewModel: viewModel)
        return dataSource
    }
    
    override func refreshControlDidRefresh() {
        self.viewModel.sync()
    }
 
    override func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        
        let inset: CGFloat = 4
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 3 : 2
        let item = self.dataSource.generateCollectionLayoutItem()
        let itemSizeWidth = (layoutEnvironment.container.contentSize.width - 2 * inset) / CGFloat(lineCount)
        let itemSizeHeight = itemSizeWidth
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

extension STAlbumsVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let album = self.dataSource.object(at: indexPath) else {
            return
        }
        self.performSegue(withIdentifier: self.segueIdentifierAlbumFiles, sender: album)
    }
    
}
