//
//  STAlbumsVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import Foundation
import StingleRoot

class STAlbumsVM {
    
    private let syncManager = STApplication.shared.syncManager
    private let albumWorker = STAlbumWorker()
    
    func sync() {
        self.syncManager.sync()
    }
    
    func createAlbum(with name: String, compliation: @escaping (_ error: IError?) -> Void) {
        self.albumWorker.createAlbum(name: name) { (album) in
            compliation(nil)
        } failure: { (error) in
            compliation(error)
        }
        
    }
    
    func deleteAlbum(album: STLibrary.Album, compliation: @escaping (_ error: IError?) -> Void) {
        self.albumWorker.deleteAlbumWithFiles(album: album) { _ in
            compliation(nil)
        } failure: { error in
            compliation(error)
        }
    }
    
        
}
