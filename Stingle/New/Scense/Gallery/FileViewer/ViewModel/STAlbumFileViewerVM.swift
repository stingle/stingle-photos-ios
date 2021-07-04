//
//  STFileViewerAlbumVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/18/21.
//

import Foundation

class STAlbumFileViewerVM: STFileViewerVM<STCDAlbumFile> {
    
    let album: STLibrary.Album
    
    init(album: STLibrary.Album, sortDescriptorsKeys: [String]) {
        self.album = album
        let predicate = NSPredicate(format: "\(#keyPath(STCDAlbumFile.albumId)) == %@", album.albumId)
        let dataBase = STApplication.shared.dataBase.albumFilesProvider
        let dataSource = dataBase.createDataSource(sortDescriptorsKeys: sortDescriptorsKeys, sectionNameKeyPath: nil, predicate: predicate, cacheName: nil)
        super.init(dataSource: dataSource)
    }
    
    override func getObject(at index: Int) -> STLibrary.AlbumFile? {
        let file = super.getObject(at: index)
        file?.updateIfNeeded(albumMetadata: self.album.albumMetadata)
        return file
    }
    
}
