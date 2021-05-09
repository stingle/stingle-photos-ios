//
//  STMoveAlbumFilesVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/8/21.
//

import Foundation

class STMoveAlbumFilesVM {
    
    private let albumWorker = STAlbumWorker()
    
    private(set) var isDeleteFilesLastValue: Bool {
        set {
            STAppSettings.isDeleteFilesWhenMoving = newValue
        } get {
            return STAppSettings.isDeleteFilesWhenMoving
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
}
