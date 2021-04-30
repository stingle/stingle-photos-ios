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
                             isRemote: data.isRemote)
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
    
    private let viewModel = STAlbumFilesVM()
    var album: STLibrary.Album!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl.isEnabled = false
    }
    
    override func configureLocalize() {
        self.navigationItem.title = self.album.albumMetadata?.name
        self.emptyDataTitleLabel?.text = "empy_gallery_title".localized
        self.emptyDataSubTitleLabel?.text = "empy_gallery_message".localized
    }
    
    override func refreshControlDidRefresh() {
        super.refreshControlDidRefresh()
        self.viewModel.sync()
    }
    
    override func createDataSource() -> STCollectionViewDataSource<ViewModel> {
        let dbDataSource = self.viewModel.createDBDataSource(albumID: self.album.albumId)
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

}
