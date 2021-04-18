//
//  STAlbumDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/15/21.
//

import UIKit
import CoreData

protocol STAlbumsDataSourceViewModelDelegate: class {
    
    func viewModel(viewModel: STAlbumsDataSource.ViewModel, albumMedadataFor album: STLibrary.Album) -> (countFiles: Int, file: STLibrary.AlbumFile?)
    
}

extension STAlbumsDataSource {
    
    struct ViewModel: ICollectionDataSourceNoHeaderViewModel {
        
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
        
        typealias Cell = STAlbumsCollectionViewCell
        typealias Model = STLibrary.Album
        
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

class STAlbumsDataSource: STCollectionViewDataSource<STAlbumsDataSource.ViewModel> {
    
    lazy var albumFilesDataSource: STDataBase.DataSource<STCDAlbumFile> = {
        let dataSource = STApplication.shared.dataBase.albumFilesProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbumFile.albumId), #keyPath(STCDAlbumFile.dateCreated)], sectionNameKeyPath: #keyPath(STCDAlbumFile.albumId))
        return dataSource
    }()
    
    init(collectionView: UICollectionView) {
        let viewModel = ViewModel()
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        let dbDataSource = albumsProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbum.dateModified)], sectionNameKeyPath: nil)
        super.init(dbDataSource: dbDataSource, collectionView: collectionView, viewModel: viewModel)
        self.viewModel.delegate = self
        self.albumFilesDataSource.delegate = self
        self.albumFilesDataSource.reloadData()
    }
        
    override func didChangeContent(with snapshot: NSDiffableDataSourceSnapshotReference) {
        if snapshot == self.snapshotReference, self.albumFilesDataSource.snapshotReference != nil {
            super.didChangeContent(with: snapshot)
        } else if snapshot == self.albumFilesDataSource.snapshotReference {
            self.reloadVisibleItems()
        }
    }
    
}

extension STAlbumsDataSource: STAlbumsDataSourceViewModelDelegate {
    
    func viewModel(viewModel: ViewModel, albumMedadataFor album: STLibrary.Album) -> (countFiles: Int, file: STLibrary.AlbumFile?) {
        var countFiles: Int = 0
        var file: STLibrary.AlbumFile?
        if let filesSnapshotReference = self.albumFilesDataSource.snapshotReference, let fileSectionIndex = filesSnapshotReference.sectionIdentifiers.firstIndex(where: {$0 as? String == album.albumId}) {
            countFiles = filesSnapshotReference.numberOfItems(inSection: album.albumId)
            file = self.albumFilesDataSource.object(at: IndexPath(row: 0, section: fileSectionIndex))
        }
        return (countFiles, file)
        
    }
    
    
}





