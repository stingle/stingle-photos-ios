//
//  STViewDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/16/21.
//

import UIKit

protocol IViewDataSource: AnyObject {
    func reloadData()
}

class STViewDataSource<Model: ICDConvertable>: NSObject, IViewDataSource, IProviderDelegate {
    
    var snapshotReference: NSDiffableDataSourceSnapshotReference? {
        return self.dbDataSource.snapshotReference
    }
    
    let dbDataSource: STDataBase.DataSource<Model>
    
    init(dbDataSource: STDataBase.DataSource<Model>) {
        self.dbDataSource = dbDataSource
        super.init()
        dbDataSource.delegate = self
    }
    
    //MARK: - Public func
    
    func reloadData() {
        self.dbDataSource.reloadData()
    }
    
    func object(at indexPath: IndexPath) -> Model? {
        return self.dbDataSource.object(at: indexPath)
    }
    
    func indexPath(at object: Model) -> IndexPath? {
        return self.dbDataSource.indexPath(forObject: object)
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


