//
//  STTrashFileViewerVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/3/21.
//

import Foundation
import StingleRoot

class STTrashFileViewerVM: STFileViewerVM<STLibrary.TrashFile> {
    
    init(sortDescriptorsKeys: [STDataBase.DataSource<STLibrary.TrashFile>.Sort]) {
        let dataBase = STApplication.shared.dataBase.trashProvider
        let dataSource = dataBase.createDataSource(sortDescriptorsKeys: sortDescriptorsKeys, sectionNameKeyPath: nil, predicate: nil, cacheName: nil)
        super.init(dataSource: dataSource)
    }
    
    override func deleteFile(file: STLibrary.TrashFile, completion: @escaping (_ result: IError?) -> Void) {
        fatalError("thish methot must be implemented chile classe")
    }
    
    override func getDeleteFileMessage(file: STLibrary.TrashFile) -> String {
        fatalError("thish methot must be implemented chile classe")
    }
    
    override func getAction(for file: STLibrary.TrashFile) -> [STFileViewerVC.ActionType] {
        return []
    }
    
}
