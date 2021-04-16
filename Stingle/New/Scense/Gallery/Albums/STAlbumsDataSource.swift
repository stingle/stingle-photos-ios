//
//  STAlbumDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/15/21.
//

import UIKit

extension STAlbumsDataSource {
    
    struct ViewModel: ICollectionDataSourceNoHeaderViewModel {
        
        static let imageBlankImageName = "__b__"
        
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
            return CellModel(image: nil, placeholder: nil, title: nil, subTille: nil)
        }
        
        func cellModel(for album: STLibrary.Album, file: STLibrary.AlbumFile?, countFiles: Int) -> CellModel {
            
            let placeholder = UIImage(named: "timer")
            var image: STImageView.Image?
                       
            switch album.cover {
            case ViewModel.imageBlankImageName:
                break
            case nil:
                if let file = file {
                    image = STImageView.Image(album: album, albumFile: file, isThumb: true)
                }
            default:
                break
            }
            
            let title = album.albumMetadata?.name
            let subTille = String(format: "items_count".localized, "\(countFiles)")
            return CellModel(image: image, placeholder: placeholder, title: title, subTille: subTille)
        }
        
    }
    
}

class STAlbumsDataSource: STCollectionViewDataSource<STAlbumsDataSource.ViewModel> {
    
    lazy var albumFilesDataSource: STDataBase.DataSource<STCDAlbumFile> = {
        return STApplication.shared.dataBase.albumFilesProvider.createDataSource(sortDescriptorsKeys: ["dateCreated"], sectionNameKeyPath: #keyPath(STCDAlbumFile.albumId))
    }()
    
    init(collectionView: UICollectionView) {
        let viewModel = ViewModel()
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        let dbDataSource = albumsProvider.createDataSource(sortDescriptorsKeys: ["dateCreated"], sectionNameKeyPath: nil)
        super.init(dbDataSource: dbDataSource, collectionView: collectionView, viewModel: viewModel)
        self.albumFilesDataSource.reloadData()
    }
    
    
    override func cellFor(collectionView: UICollectionView, indexPath: IndexPath, data: Any) -> STCollectionViewDataSource<ViewModel>.Cell? {
        
        guard let object = self.object(at: indexPath) else {
            let cell = super.cellFor(collectionView: collectionView, indexPath: indexPath, data: data)
            return cell
        }
        
        var countFiles = 0
        var file: STLibrary.AlbumFile?
        
        if let filesSnapshotReference = self.albumFilesDataSource.snapshotReference, let fileSectionIndex = filesSnapshotReference.sectionIdentifiers.firstIndex(where: {object.albumId == $0 as? String}) {
            file = self.albumFilesDataSource.object(at: IndexPath(item: 0, section: fileSectionIndex))
            countFiles = filesSnapshotReference.numberOfItems(inSection: object.albumId)
        }
        
        let cellModel = self.viewModel.cellModel(for: object, file: file, countFiles: countFiles)

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellModel.identifier.identifier, for: indexPath) as! Cell
        cell.configure(model: cellModel)
        return cell
    }
    
    override func didChangeContent(with snapshot: NSDiffableDataSourceSnapshotReference) {
       
        
        if snapshot == self.snapshotReference {
            super.didChangeContent(with: snapshot)
        }

        
    }
    
}



