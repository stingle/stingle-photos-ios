//
//  STFileViewerFileVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/18/21.
//

import Foundation
import StingleRoot

class STGaleryFileViewerVM: STFileViewerVM<STLibrary.GaleryFile> {
    
    private let fileWorker = STFileWorker()
    
    init(sortDescriptorsKeys: [STDataBase.DataSource<STLibrary.GaleryFile>.Sort], predicate: NSPredicate?) {
        let dataBase = STApplication.shared.dataBase.galleryProvider
        let dataSource = dataBase.createDataSource(sortDescriptorsKeys: sortDescriptorsKeys, sectionNameKeyPath: nil, predicate: predicate, cacheName: nil)
        super.init(dataSource: dataSource)
    }
    
    override func getDeleteFileMessage(file: STLibrary.GaleryFile) -> String {
        return "move_trash_file_alert_message".localized
    }
    
    override func deleteFile(file: STLibrary.GaleryFile, completion: @escaping (IError?) -> Void) {
        self.fileWorker.moveFilesToTrash(files: [file], reloadDBData: true) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }

    override func getAction(for file: STLibrary.GaleryFile) -> [STFileViewerVC.ActionType] {
        return self.getDefaultActions(for: file)
    }
    
    override func moveInfo(for file: STLibrary.GaleryFile) -> STMoveAlbumFilesVC.MoveInfo {
        return .files(files: [file])
    }

    override func editVM(for file: STLibrary.GaleryFile) -> IFileEditVM {
        return STGaleryFileEditVM(file: file)
    }
    
    override func getShearedType(for file: STLibrary.GaleryFile) -> STSharedMembersVC.ShearedType {
        return .files(files: [file])
    }

}
