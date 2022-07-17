//
//  STViewDataSource.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/16/21.
//

import UIKit

public protocol IViewDataSource: AnyObject {
    func reloadData()
}

open class STViewDataSource<Model: ICDConvertable>: NSObject, IViewDataSource, IProviderDelegate {
    
    var snapshotReference: NSDiffableDataSourceSnapshotReference? {
        return self.dbDataSource.snapshotReference
    }
    
    let dbDataSource: STDataBase.DataSource<Model>
    
    init(dbDataSource: STDataBase.DataSource<Model>) {
        self.dbDataSource = dbDataSource
        super.init()
        dbDataSource.delegate = self
        
        let name = NSNotification.Name.init(rawValue: "ffffff")
        
        NotificationCenter.default.addObserver(self, selector: #selector(hello), name: name, object: nil)
        
    }
    
    @objc func hello() {
        
        print("")
        
    }
    
    //MARK: - Public func
    
    public func reloadData() {
        self.dbDataSource.reloadData()
    }
    
    public func object(at indexPath: IndexPath) -> Model? {
        return self.dbDataSource.object(at: indexPath)
    }
    
    public func indexPath(at object: Model) -> IndexPath? {
        return self.dbDataSource.indexPath(forObject: object)
    }
        
    //MARK: Internal
    
    public func didChangeContent(with snapshot: NSDiffableDataSourceSnapshotReference) {}
    public func didStartSync(dataSource: IProviderDataSource) {}
    public func didEndSync(dataSource: IProviderDataSource) {}
        
    public func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.didChangeContent(with: snapshot)
    }

}

public extension STViewDataSource {
    
    var isEmptyData: Bool {
        return (self.snapshotReference?.numberOfItems ?? .zero) == .zero
    }
    
}


