//
//  STMoveAlbumFilesVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/8/21.
//

import Foundation
import StingleRoot

class STMoveAlbumFilesVM {
    
    private let albumWorker = STAlbumWorker()
    private let fileWorker = STFileWorker()
    
    private(set) var isDeleteFilesLastValue: Bool {
        set {
            STAppSettings.current.isDeleteFilesWhenMoving = newValue
        } get {
            return STAppSettings.current.isDeleteFilesWhenMoving
        }
    }
    
    func moveToAlbum(toAlbum: STLibrary.Album, files: [STLibrary.GaleryFile], isDeleteFiles: Bool, result: @escaping (_ result: IError?) -> Void) {
        self.isDeleteFilesLastValue = isDeleteFiles
        let isMoving = self.isDeleteFilesLastValue
        self.albumWorker.moveFiles(files: files, toAlbum: toAlbum, isMoving: isMoving) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    
    func moveToAlbum(fromAlbum: STLibrary.Album, toAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isDeleteFiles: Bool, result: @escaping (_ result: IError?) -> Void) {
        self.isDeleteFilesLastValue = isDeleteFiles
        let isMoving = self.isDeleteFilesLastValue && fromAlbum.isOwner
        self.albumWorker.moveFiles(fromAlbum: fromAlbum, toAlbum: toAlbum, files: files, isMoving: isMoving, reloadDBData: true) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func moveFilesToGallery(fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isDeleteFiles: Bool, result: @escaping (_ result: IError?) -> Void) {
        self.isDeleteFilesLastValue = isDeleteFiles
        let isMoving = self.isDeleteFilesLastValue && fromAlbum.isOwner
        self.albumWorker.moveFilesToGallery(fromAlbum: fromAlbum, files: files, isMoving: isMoving) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func createAlbum(name: String, fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isDeleteFiles: Bool, result: @escaping (_ result: IError?) -> Void) {
        self.isDeleteFilesLastValue = isDeleteFiles
        let isMoving = self.isDeleteFilesLastValue && fromAlbum.isOwner
        self.albumWorker.createAlbum(name: name, fromAlbum: fromAlbum, files: files, isMoving: isMoving) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
    func createAlbum(name: String, result: @escaping (_ result: IError?) -> Void) {
        self.albumWorker.createAlbum(name: name) { album in
            result(nil)
        } failure: { error in
            result(error)
        }        
    }
    
}
