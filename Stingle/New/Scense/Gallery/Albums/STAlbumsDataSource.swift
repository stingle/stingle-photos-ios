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
    private var albumInfoFiles = [String: AlbumInfo]()
    
    init(collectionView: UICollectionView, predicate: NSPredicate?, viewModel: ViewModel) {
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        let dbDataSource = albumsProvider.createDataSource(sortDescriptorsKeys: [#keyPath(STCDAlbum.dateModified)], sectionNameKeyPath: nil, predicate: predicate, cacheName: nil)
        super.init(dbDataSource: dbDataSource, collectionView: collectionView, viewModel: viewModel)
        self.viewModel.delegate = self
        STApplication.shared.dataBase.albumFilesProvider.add(self)
    }
    
}

extension STAlbumsDataSource: STAlbumsDataSourceViewModelDelegate {
    
    struct AlbumInfo {
        let albumFile: STLibrary.AlbumFile?
        let countFiles: Int
    }
    
    func viewModel(albumMedadataFor album: STLibrary.Album) -> (countFiles: Int, file: STLibrary.AlbumFile?, members: [STContact]?) {
        var albumInfo: AlbumInfo!
        let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
        if let info = self.albumInfoFiles[album.albumId] {
            albumInfo = info
        } else {
            let albumFiles = albumFilesProvider.fetch(for: album.albumId, sortDescriptorsKeys: [#keyPath(STCDAlbumFile.dateCreated)], ascending: false)
            if album.cover == STLibrary.Album.imageBlankImageName {
                albumInfo = AlbumInfo(albumFile: nil, countFiles: albumFiles.count)
            } else if let cover = album.cover {
                if  let first = albumFiles.first(where: { $0.file == cover }) {
                    let albumFile = try? STLibrary.AlbumFile(model: first)
                    albumInfo = AlbumInfo(albumFile: albumFile, countFiles: albumFiles.count)
                } else {
                    albumInfo = AlbumInfo(albumFile: nil, countFiles: albumFiles.count)
                }
            } else {
                if let first = albumFiles.first {
                    let albumFile = try? STLibrary.AlbumFile(model: first)
                    albumInfo = AlbumInfo(albumFile: albumFile, countFiles: albumFiles.count)
                } else {
                    albumInfo = AlbumInfo(albumFile: nil, countFiles: albumFiles.count)
                }
            }
        }
        
        if self.contacts == nil {
            self.contacts = STApplication.shared.dataBase.contactProvider.fetchAllObjects()
        }
        
        let members = album.members?.components(separatedBy: ",")
        let contacts = self.contacts?.filter({ members?.contains($0.userId) ?? false })
        return (albumInfo.countFiles, albumInfo.albumFile, contacts)
    }
    
}

extension STAlbumsDataSource: ICollectionProviderObserver {
    
    func dataBaseCollectionProvider(didAdded provider: ICollectionProvider, models: [IDataBaseProviderModel]) {
        if provider === STApplication.shared.dataBase.contactProvider {
            self.contacts = nil
        } else if provider === STApplication.shared.dataBase.albumFilesProvider {
            self.albumInfoFiles.removeAll()
        }
    }
    
    func dataBaseCollectionProvider(didDeleted provider: ICollectionProvider, models: [IDataBaseProviderModel]) {
        if provider === STApplication.shared.dataBase.contactProvider {
            self.contacts = nil
        } else if provider === STApplication.shared.dataBase.albumFilesProvider {
            self.albumInfoFiles.removeAll()
        }
    }
    
    func dataBaseCollectionProvider(didUpdated provider: ICollectionProvider, models: [IDataBaseProviderModel]) {
        if provider === STApplication.shared.dataBase.contactProvider {
            self.contacts = nil
        } else if provider === STApplication.shared.dataBase.albumFilesProvider {
            self.albumInfoFiles.removeAll()
        }
    }
    
}
