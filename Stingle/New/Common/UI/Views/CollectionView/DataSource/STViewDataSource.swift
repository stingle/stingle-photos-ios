//
//  STViewDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/16/21.
//

import UIKit

protocol IViewDataSource: class {
    func reloadData()
}

class STViewDataSource<Model: ICDConvertable>: IViewDataSource, IProviderDelegate where Model == Model.ManagedModel.Model {
    
    var snapshotReference: NSDiffableDataSourceSnapshotReference? {
        return self.dbDataSource.snapshotReference
    }
    
    let dbDataSource: STDataBase.DataSource<Model.ManagedModel>
    
    init(dbDataSource: STDataBase.DataSource<Model.ManagedModel>) {
        self.dbDataSource = dbDataSource
        dbDataSource.delegate = self
    }
    
    //MARK: - Public func
    
    func reloadData() {
        self.dbDataSource.reloadData()
    }
    
    func object(at indexPath: IndexPath) -> Model? {
        return self.dbDataSource.object(at: indexPath)
    }
    
    //MARK: Internal
    
    func didStartSync() {
        
    }
    
    func didChangeContent(with snapshot: NSDiffableDataSourceSnapshotReference) {
        
    }
    
    func didEndSync() {
        
    }
    
    func didStartSync(dataSource: IProviderDataSource) {
        self.didStartSync()
    }
    
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.didChangeContent(with: snapshot)
    }
    
    func didEndSync(dataSource: IProviderDataSource) {
        self.didEndSync()
    }
    
}
