//
//  STFileViewerVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/18/21.
//

import UIKit

protocol IFileViewerVM {
    
    var delegate: STFileViewerVMDelegate? { get set }
    func object(at index: Int) -> STLibrary.File?
    func index(at file: STLibrary.File) -> Int?
    var countOfItems: Int { get }
    
}

extension IFileViewerVM {
    
    func object(at index: Int) -> STLibrary.File? {
        return nil
    }
    
    func index(at file: STLibrary.File) -> Int? {
        return nil
    }
}

protocol STFileViewerVMDelegate: AnyObject {
    func fileViewerVM(didUpdateedData fileViewerVM: IFileViewerVM)
}

class STFileViewerVM<ManagedObject: IManagedObject> where ManagedObject.Model == STLibrary.File {
    
    private let dataSource: STDataBase.DataSource<ManagedObject>
    private var snapshot: NSDiffableDataSourceSnapshotReference?
    
    weak var delegate: STFileViewerVMDelegate?
    
    init(dataSource: STDataBase.DataSource<ManagedObject>) {
        self.dataSource = dataSource
        self.dataSource.delegate = self
        self.dataSource.reloadData()
    }
    
    func getObject(at index: Int) -> ManagedObject.Model? {
        guard index < self.countOfItems, index >= .zero else {
            return nil
        }
        let indexPath = IndexPath(item: index, section: .zero)
        return self.dataSource.object(at: indexPath)
    }
    
    func getIndex(at model: ManagedObject.Model) -> Int? {
        let indexPath = self.dataSource.indexPath(forObject: model)
        return indexPath?.row
    }
        
}

extension STFileViewerVM: IFileViewerVM {
    
    func object(at index: Int) -> STLibrary.File? {
        return self.getObject(at: index)
    }
    
    func index(at file: STLibrary.File) -> Int? {
        return self.getIndex(at: file)
    }
        
}


extension STFileViewerVM: IProviderDelegate {
    
    var countOfItems: Int {
        return self.snapshot?.numberOfItems ?? .zero
    }
    
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.snapshot = snapshot
        self.delegate?.fileViewerVM(didUpdateedData: self)
    }

}
