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

    let dbDataSource: STDataBase.DataSource<Model>

    init(dbDataSource: STDataBase.DataSource<Model>) {
        self.dbDataSource = dbDataSource
        super.init()
        dbDataSource.delegate = self
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

    //MARK: Internal — overridable hooks

    /// Apply an incremental change set to the UI (cost = O(changes)). Overridden by the collection-view
    /// data source to drive `performBatchUpdates`.
    open func didChangeContent(changes: STDataSourceChanges) {}

    /// Full reload after `performFetch` (initial load, unlock, or a too-large delta).
    open func didReloadData() {}

    open func didStartSync(dataSource: IProviderDataSource) {}
    open func didEndSync(dataSource: IProviderDataSource) {}

    //MARK: - IProviderDelegate

    public func dataSource(_ dataSource: IProviderDataSource, didChange changes: STDataSourceChanges) {
        self.didChangeContent(changes: changes)
    }

    public func dataSourceDidReloadData(_ dataSource: IProviderDataSource) {
        self.didReloadData()
    }

}

public extension STViewDataSource {

    var isEmptyData: Bool {
        return self.dbDataSource.numberOfItems == .zero
    }

}
