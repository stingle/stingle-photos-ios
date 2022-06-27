//
//  STFileViewerAlbumVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/18/21.
//

import Foundation

class STAlbumFileViewerVM: STFileViewerVM<STLibrary.AlbumFile> {
    
    private let album: STLibrary.Album
    private let albumWorker = STAlbumWorker()
    
    init(album: STLibrary.Album, sortDescriptorsKeys: [STDataBase.DataSource<STLibrary.AlbumFile>.Sort]) {
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
    
    override func getAction(for file: STLibrary.AlbumFile) -> [STFileViewerVC.ActionType] {
        if self.album.isOwner {
            return self.getDefaultActions(for: file)
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
    
    override func deleteFile(file: STLibrary.AlbumFile, completion: @escaping (_ result: IError?) -> Void) {
        self.albumWorker.deleteAlbumFiles(album: self.album, files: [file]) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    override func getDeleteFileMessage(file: STLibrary.AlbumFile) -> String {
        return "move_trash_file_alert_message".localized
    }
    
    override func getMorAction(for file: STLibrary.AlbumFile) -> [STFileViewerVC.MoreAction] {
        return [.download, .setAlbumCover]
    }
    
    override func selectMore(action: STFileViewerVC.MoreAction, file: STLibrary.AlbumFile) {
        switch action {
        case .download:
            self.downloadFile(file: file)
        case .setAlbumCover:
            self.albumWorker.setCover(album: self.album, caver: file.file, success: { _ in
            }, failure: nil)
        }
    }
    
    override func moveInfo(for file: STLibrary.AlbumFile) -> STMoveAlbumFilesVC.MoveInfo {
        return .albumFiles(album: self.album, files: [file])
    }

    override func editVM(for file: STLibrary.AlbumFile) -> IFileEditVM {
        return STAlbumFileEditVM(file: file, album: self.album)
    }
    
    override func getShearedType(for file: STLibrary.AlbumFile) -> STSharedMembersVC.ShearedType {
        return .albumFiles(album: self.album, files: [file])
    }

}
