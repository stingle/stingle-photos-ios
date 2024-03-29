//
//  STShareAlbumVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/3/21.
//

import Foundation
import StingleRoot

class STShareAlbumVM {
    
    typealias Permitions = (addPhoto: Bool, sharing: Bool, copying: Bool)
    
    let albumFilesProvider = STApplication.shared.dataBase.albumFilesProvider
    let albumWorker = STAlbumWorker()
    
    func shareAlbum(album: STLibrary.Album, contact: [STContact], permitions: Permitions, result: @escaping (_ result: IError?) -> Void) {

        let permitions = STLibrary.Album.Permission(allowAdd: permitions.addPhoto, allowShare: permitions.sharing, allowCopy: permitions.copying)
        self.albumWorker.shareAlbum(album: album, contacts: contact, permitions: permitions) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func shareAlbumFiles(name: String, album: STLibrary.Album, files: [STLibrary.AlbumFile], contact: [STContact], permitions: Permitions, result: @escaping (_ result: IError?) -> Void) {
    
        let permitions = STLibrary.Album.Permission(allowAdd: permitions.addPhoto, allowShare: permitions.sharing, allowCopy: permitions.copying)
        
        self.albumWorker.createSharedAlbum(name: name, fromAlbum: album, files: files, contacts: contact, permitions: permitions) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }

    }
    
    func shareFiles(name: String, files: [STLibrary.GaleryFile], contact: [STContact], permitions: Permitions, result: @escaping (_ result: IError?) -> Void) {
        
        let permitions = STLibrary.Album.Permission(allowAdd: permitions.addPhoto, allowShare: permitions.sharing, allowCopy: permitions.copying)
        
        self.albumWorker.createSharedAlbum(name: name, files: files, contacts: contact, permitions: permitions) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }

    }
        
}

extension STShareAlbumVM {
    
    enum ShareAlbumError: IError {
        case hasIsRemoteItems
        case emptyData
        
        var message: String {
            switch self {
            case .hasIsRemoteItems:
                return "please_wait_for_backup_to_finish_before_you_can_proceed".localized
            case .emptyData:
                return "empty_data".localized
            }
        }
    }
    
}
