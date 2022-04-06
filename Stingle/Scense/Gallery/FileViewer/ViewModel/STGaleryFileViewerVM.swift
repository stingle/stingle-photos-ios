//
//  STFileViewerFileVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/18/21.
//

import Foundation

class STGaleryFileViewerVM: STFileViewerVM<STCDFile> {
    
    private let fileWorker = STFileWorker()
    
    init(sortDescriptorsKeys: [STDataBase.DataSource<STCDFile>.Sort], predicate: NSPredicate?) {
        let dataBase = STApplication.shared.dataBase.galleryProvider
        let dataSource = dataBase.createDataSource(sortDescriptorsKeys: sortDescriptorsKeys, sectionNameKeyPath: nil, predicate: predicate, cacheName: nil)
        super.init(dataSource: dataSource)
    }
    
    override func getDeleteFileMessage(file: STLibrary.File) -> String {
        return "move_trash_file_alert_message".localized
    }
    
    override func deleteFile(file: STLibrary.File, completion: @escaping (IError?) -> Void) {
        self.fileWorker.moveFilesToTrash(files: [file], reloadDBData: true) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }

    override func getAction(for file: STLibrary.File) -> [STFileViewerVC.ActionType] {
        var allCasesWithoutEdit = STFileViewerVC.ActionType.allCases.filter({ $0 != .edit })
        guard let originalType = file.decryptsHeaders.file?.fileOreginalType else {
            return allCasesWithoutEdit
        }
        switch originalType {
        case .video:
            return allCasesWithoutEdit
        case .image:
            allCasesWithoutEdit.append(.edit)
            return allCasesWithoutEdit
        }
    }

    override func editVM(for file: STLibrary.File) -> IFileEditVM {
        return STGaleryFileEditVM(file: file)
    }

}
