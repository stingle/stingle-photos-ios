//
//  STGalleryVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/16/21.
//

import Foundation

class STGalleryVM {
    
    private(set) var dataBaseDataSource: STDataBase.DataSource<STLibrary.File>
    private let syncWorker = STSyncWorker()
    private let crypto = STApplication.shared.crypto
    
    init() {
        self.dataBaseDataSource = STApplication.shared.dataBase.galleryProvider.createDataSource(sortDescriptorsKeys: ["dateCreated"], sectionNameKeyPath: #keyPath(STCDFile.day))
        
        self.syncWorker.getUpdates { (_) in
           print("")
        } failure: { (error) in
            print("")
        }

        
    }
    
    func reloadData() {
        self.dataBaseDataSource.reloadData()
    }
    
}

extension STGalleryVM {
    
    func sectionTitle(at secction: Int) -> String? {
        return self.dataBaseDataSource.sectionTitle(at: secction)
    }
    
    func object(at indexPath: IndexPath) -> STLibrary.File? {
                
        if let file = self.dataBaseDataSource.object(at: indexPath) {
            
            let headers = self.crypto.getHeaders(file: file)
            
            print("")
            return file
        }
        
        
        return nil
    }
    
    
}


extension STCDFile {
    
    @objc var day: String {
        let str = STDateManager.shared.dateToString(date: self.dateCreated, withFormate: .mmm_dd_yyyy)
        return str
    }
    
}
