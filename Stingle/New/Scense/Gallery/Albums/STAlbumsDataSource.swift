//
//  STAlbumDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/15/21.
//

import UIKit
import CoreData

protocol STAlbumsDataSourceViewModelDelegate: AnyObject {
    func viewModel(albumMedadataFor album: STLibrary.Album) -> (countFiles: Int, file: STLibrary.AlbumFile?, members: [STContact]?)
}

protocol IAlbumsViewModel: ICollectionDataSourceViewModel where CDModel == STCDAlbum {
    var delegate: STAlbumsDataSourceViewModelDelegate? { get set }
}

class STAlbumsDataSource<ViewModel: IAlbumsViewModel>: STCollectionViewDataSource<ViewModel> {
    
    private var contacts: [STContact]?
    
    lazy var albumFilesDataSource: STDataBase.DataSource<STCDAlbumFile> = {
        let dataSource = STApplication.shared.dataBase.albumFilesProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbumFile.albumId), #keyPath(STCDAlbumFile.dateCreated)], sectionNameKeyPath: #keyPath(STCDAlbumFile.albumId), predicate: nil, cacheName: nil)
        return dataSource
    }()
    
    init(collectionView: UICollectionView, predicate: NSPredicate?, viewModel: ViewModel) {
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        let dbDataSource = albumsProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbum.dateModified)], sectionNameKeyPath: nil, predicate: predicate, cacheName: nil)
        super.init(dbDataSource: dbDataSource, collectionView: collectionView, viewModel: viewModel)
        self.viewModel.delegate = self
        self.albumFilesDataSource.delegate = self
        self.albumFilesDataSource.reloadData()
    }
    
    convenience init(collectionView: UICollectionView, isShared: Bool, viewModel: ViewModel) {
        let predicate = NSPredicate(format: "isShared == %i", isShared)
        self.init(collectionView: collectionView, predicate: predicate, viewModel: viewModel)
    }
        
    override func didChangeContent(with snapshot: NSDiffableDataSourceSnapshotReference) {
        if snapshot == self.snapshotReference, self.albumFilesDataSource.snapshotReference != nil {
            self.contacts = nil
            super.didChangeContent(with: snapshot)
        }  else {
            self.reloadCollectionVisibleCells()
        }
    }
    
}

extension STAlbumsDataSource: STAlbumsDataSourceViewModelDelegate {
    
    func viewModel(albumMedadataFor album: STLibrary.Album) -> (countFiles: Int, file: STLibrary.AlbumFile?, members: [STContact]?) {
        var countFiles: Int = 0
        var file: STLibrary.AlbumFile?
        if let filesSnapshotReference = self.albumFilesDataSource.snapshotReference, let fileSectionIndex = filesSnapshotReference.sectionIdentifiers.firstIndex(where: {$0 as? String == album.albumId}) {
            countFiles = filesSnapshotReference.numberOfItems(inSection: album.albumId)
            file = self.albumFilesDataSource.object(at: IndexPath(row: 0, section: fileSectionIndex))
        }
        if self.contacts == nil {
            self.contacts = STApplication.shared.dataBase.contactProvider.fetchAllObjects()
        }
        let members = album.members?.components(separatedBy: ",")
        let contacts = self.contacts?.filter({ members?.contains($0.userId) ?? false })
        return (countFiles, file, contacts)
        
    }
    
}
