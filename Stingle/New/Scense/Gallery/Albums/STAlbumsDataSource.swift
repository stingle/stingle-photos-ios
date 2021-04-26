//
//  STAlbumDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/15/21.
//

import UIKit
import CoreData

protocol STAlbumsDataSourceViewModelDelegate: class {
    func viewModel(albumMedadataFor album: STLibrary.Album) -> (countFiles: Int, file: STLibrary.AlbumFile?, members: [STContact]?)
}

protocol IAlbumsViewModel: ICollectionDataSourceViewModel where CDModel == STCDAlbum {
    var delegate: STAlbumsDataSourceViewModelDelegate? { get set }
}

class STAlbumsDataSource<ViewModel: IAlbumsViewModel>: STCollectionViewDataSource<ViewModel> {
    
    private var contacts: [STContact]?
    
    lazy var albumFilesDataSource: STDataBase.DataSource<STCDAlbumFile> = {
        let dataSource = STApplication.shared.dataBase.albumFilesProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbumFile.albumId), #keyPath(STCDAlbumFile.dateCreated)], sectionNameKeyPath: #keyPath(STCDAlbumFile.albumId))
        return dataSource
    }()
    
    init(collectionView: UICollectionView, predicate: NSPredicate?, viewModel: ViewModel) {
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        var cacheName = STCDAlbumFile.entityName
        if let predicate = predicate {
            cacheName = cacheName + predicate.predicateFormat
        }
        let dbDataSource = albumsProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbum.dateModified)], sectionNameKeyPath: nil, predicate: predicate, cacheName: cacheName)
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
        } else if snapshot == self.albumFilesDataSource.snapshotReference {
            self.reloadVisibleItems()
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
            self.contacts = STApplication.shared.dataBase.contactProvider.fetchAll()
        }
        let members = album.members?.components(separatedBy: ",")
        let contacts = self.contacts?.filter({ members?.contains($0.userId) ?? false })
        return (countFiles, file, contacts)
        
    }
    
}
