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

class STViewDataSource<Model: IManagedObject>: IViewDataSource, IProviderDelegate {
    
    var snapshotReference: NSDiffableDataSourceSnapshotReference? {
        return self.dbDataSource.snapshotReference
    }
    
    let dbDataSource: STDataBase.DataSource<Model>
    
    init(dbDataSource: STDataBase.DataSource<Model>) {
        self.dbDataSource = dbDataSource
        dbDataSource.delegate = self
    }
    
    //MARK: - Public func
    
    func reloadData() {
        self.dbDataSource.reloadData()
    }
    
    func object(at indexPath: IndexPath) -> Model.Model? {
        return self.dbDataSource.object(at: indexPath)
    }
    
    //MARK: Internal
    
    func didChangeContent(with snapshot: NSDiffableDataSourceSnapshotReference) {}
    func didStartSync(dataSource: IProviderDataSource) {}
    func didEndSync(dataSource: IProviderDataSource) {}
        
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.didChangeContent(with: snapshot)
    }

}

extension STViewDataSource {
    
    var isEmptyData: Bool {
        return (self.snapshotReference?.numberOfItems ?? .zero) == .zero
    }
    
}


