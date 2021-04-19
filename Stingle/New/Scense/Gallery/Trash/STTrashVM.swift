//
//  STTrashVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import Foundation

class STTrashVM {
    
    private let syncManager = STApplication.shared.syncManager
    
    func createDBDataSource() -> STDataBase.DataSource<STCDTrashFile> {
        return STApplication.shared.dataBase.trashProvider.createDataSource(sortDescriptorsKeys: ["dateCreated"], sectionNameKeyPath: #keyPath(STCDTrashFile.day))
    }
    
    func sync() {
        self.syncManager.sync()
    }
        
}

extension STCDTrashFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
