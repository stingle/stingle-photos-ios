//
//  STTrashFileViewerVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/3/21.
//

import Foundation

class STTrashFileViewerVM: STFileViewerVM<STCDTrashFile> {
    
    init(sortDescriptorsKeys: [STDataBase.DataSource<STCDTrashFile>.Sort]) {
        let dataBase = STApplication.shared.dataBase.trashProvider
        let dataSource = dataBase.createDataSource(sortDescriptorsKeys: sortDescriptorsKeys, sectionNameKeyPath: nil, predicate: nil, cacheName: nil)
        super.init(dataSource: dataSource)
    }
    
    override func deleteFile(file: STLibrary.File, completion: @escaping (_ result: IError?) -> Void) {
        fatalError("thish methot must be implemented chile classe")
    }
    
    override func getDeleteFileMessage(file: STLibrary.File) -> String {
        fatalError("thish methot must be implemented chile classe")
    }
    
    override func getAction(for file: STLibrary.File) -> [STFileViewerVC.ActionType] {
        return []
    }
    
}
