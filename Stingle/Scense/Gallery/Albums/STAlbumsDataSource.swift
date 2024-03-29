//
//  STAlbumDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/15/21.
//

import UIKit
import CoreData
import StingleRoot

protocol STAlbumsDataSourceViewModelDelegate: AnyObject {
    func viewModel(albumMedadataFor album: STLibrary.Album?) -> (countFiles: Int, file: STLibrary.AlbumFile?, members: [STContact]?)
}

protocol IAlbumsViewModel: ICollectionDataSourceViewModel where Model == STLibrary.Album {
    var delegate: STAlbumsDataSourceViewModelDelegate? { get set }
}

class STAlbumsDataSource<ViewModel: IAlbumsViewModel>: STCollectionViewDataSource<ViewModel> {
    
    private var contacts: [STContact]?
    private var albumInfoFiles = [String: AlbumInfo]()
    
    init(collectionView: UICollectionView, predicate: NSPredicate?, viewModel: ViewModel) {
        let albumsProvider = STApplication.shared.dataBase.albumsProvider
        let dateModified = STDataBase.DataSource<STLibrary.Album>.Sort(key: #keyPath(STCDAlbum.dateModified), ascending: false)
        let dbDataSource = albumsProvider.createDataSource(sortDescriptorsKeys: [dateModified], sectionNameKeyPath: nil, predicate: predicate, cacheName: nil)
        
        super.init(dbDataSource: dbDataSource, collectionView: collectionView, viewModel: viewModel)
        self.viewModel.delegate = self
        STApplication.shared.dataBase.albumFilesProvider.add(self)
    }
        
    override func didChangeContent(with snapshot: NSDiffableDataSourceSnapshotReference) {
        self.albumInfoFiles.removeAll()
        super.didChangeContent(with: snapshot)
    }
    
}

extension STAlbumsDataSource: STAlbumsDataSourceViewModelDelegate {
    
    struct AlbumInfo {
        let albumFile: STLibrary.AlbumFile?
        let countFiles: Int
    }
    
    func viewModel(albumMedadataFor album: STLibrary.Album?) -> (countFiles: Int, file: STLibrary.AlbumFile?, members: [STContact]?) {
        
        guard let album = album else {
            return (.zero, nil, nil)
        }
        
        var albumInfo: AlbumInfo!
        let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
        if let info = self.albumInfoFiles[album.albumId] {
            albumInfo = info
        } else {
            
            let albumFiles = albumFilesProvider.fetch(albumID: album.albumId, sortDescriptorsKeys: [#keyPath(STCDAlbumFile.dateCreated)], ascending: false)
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
            self.contacts = STApplication.shared.dataBase.contactProvider.fetchObjects()
        }
        self.albumInfoFiles[album.albumId] = albumInfo
        let members = album.members?.components(separatedBy: ",")
        let contacts = self.contacts?.filter({ members?.contains($0.userId) ?? false })
        return (albumInfo.countFiles, albumInfo.albumFile, contacts)
    }
    
}

extension STAlbumsDataSource: IDataBaseProviderProviderObserver {
    
    func dataBaseProvider(didAdded provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {
        if provider === STApplication.shared.dataBase.contactProvider {
            self.contacts = nil
        } else if provider === STApplication.shared.dataBase.albumFilesProvider {
            self.albumInfoFiles.removeAll()
        }
    }
    
    func dataBaseProvider(didDeleted provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {
        if provider === STApplication.shared.dataBase.contactProvider {
            self.contacts = nil
        } else if provider === STApplication.shared.dataBase.albumFilesProvider {
            self.albumInfoFiles.removeAll()
        }
    }
    
    func dataBaseProvider(didUpdated provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {
        if provider === STApplication.shared.dataBase.contactProvider {
            self.contacts = nil
        } else if provider === STApplication.shared.dataBase.albumFilesProvider {
            self.albumInfoFiles.removeAll()
        }
    }
    
}
