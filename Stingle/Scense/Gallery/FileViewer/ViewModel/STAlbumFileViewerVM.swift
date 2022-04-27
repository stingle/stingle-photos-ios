//
//  STFileViewerAlbumVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/18/21.
//

import Foundation

class STAlbumFileViewerVM: STFileViewerVM<STCDAlbumFile> {
    
    private let album: STLibrary.Album
    private let albumWorker = STAlbumWorker()
    
    init(album: STLibrary.Album, sortDescriptorsKeys: [STDataBase.DataSource<STCDAlbumFile>.Sort]) {
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

    override func getAction(for file: STLibrary.File) -> [STFileViewerVC.ActionType] {
        if self.album.isOwner {
            return STFileViewerVC.ActionType.allCases
        } else {
            var result = [STFileViewerVC.ActionType]()
            if self.album.permission.allowCopy {
                result.append(.move)
                result.append(.saveToDevice)
            }
            
            if self.album.permission.allowShare {
                result.append(.share)
            }
            return result
        }
    }
    
    override func deleteFile(file: STLibrary.File, completion: @escaping (_ result: IError?) -> Void) {
        guard let file = file as? STLibrary.AlbumFile else {
            completion(nil)
            return
        }
        
        self.albumWorker.deleteAlbumFiles(album: self.album, files: [file]) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    override func getDeleteFileMessage(file: STLibrary.File) -> String {
        return "move_trash_file_alert_message".localized
    }
    
    override func getMorAction(for file: STLibrary.File) -> [STFileViewerVC.MoreAction] {
        return [.download, .setAlbumCover]
    }
    
    override func selectMore(action: STFileViewerVC.MoreAction, file: STLibrary.File) {
        switch action {
        case .download:
            self.downloadFile(file: file)
        case .setAlbumCover:
            self.albumWorker.setCover(album: self.album, caver: file.file, success: { _ in
            }, failure: nil)
        }
    }
    
    override func moveInfo(for file: STLibrary.File) -> STMoveAlbumFilesVC.MoveInfo {
        guard let file = file as? STLibrary.AlbumFile else {
            fatalError("file is incorrect")
        }
        return .albumFiles(album: self.album, files: [file])
    }

    override func editVM(for file: STLibrary.File) -> IFileEditVM {
        return STAlbumFileEditVM(file: file, album: self.album)
    }

}
