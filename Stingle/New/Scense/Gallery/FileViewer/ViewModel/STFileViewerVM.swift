//
//  STFileViewerVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/18/21.
//

import UIKit

protocol IFileViewerVM {
    
    var delegate: STFileViewerVMDelegate? { get set }
    var countOfItems: Int { get }
    
    func object(at index: Int) -> STLibrary.File?
    func index(at file: STLibrary.File) -> Int?
    
    func deleteFile(file: STLibrary.File, completion: @escaping (_ result: IError?) -> Void)
    
    func getDeleteFileMessage(file: STLibrary.File) -> String
    func removeFileSystemFolder(url: URL)
    func downloadFile(file: STLibrary.File)
    
    func getAction(for file: STLibrary.File) -> [STFileViewerVC.ActionType]
    
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

class STFileViewerVM<ManagedObject: IManagedObject>: IFileViewerVM {
    
    private let dataSource: STDataBase.DataSource<ManagedObject>
    private var snapshot: NSDiffableDataSourceSnapshotReference?
    
    weak var delegate: STFileViewerVMDelegate? {
        didSet {
            self.dataSource.reloadData()
        }
    }
    
    init(dataSource: STDataBase.DataSource<ManagedObject>) {
        self.dataSource = dataSource
        self.dataSource.delegate = self
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
    
    //MARK: - IFileViewerVM
    
    func object(at index: Int) -> STLibrary.File? {
        return self.getObject(at: index) as? STLibrary.File
    }
    
    func index(at file: STLibrary.File) -> Int? {
        return self.getIndex(at: file as! ManagedObject.Model)
    }
    
    var countOfItems: Int {
        return self.snapshot?.numberOfItems ?? .zero
    }
    
    func deleteFile(file: STLibrary.File, completion: @escaping (_ result: IError?) -> Void) {
        fatalError("thish methot must be implemented chile classe")
    }
    
    func getDeleteFileMessage(file: STLibrary.File) -> String {
        fatalError("thish methot must be implemented chile classe")
    }
    
    func getAction(for file: STLibrary.File) -> [STFileViewerVC.ActionType] {
        fatalError("thish methot must be implemented chile classe")
    }
    
    func removeFileSystemFolder(url: URL) {
        STApplication.shared.fileSystem.remove(file: url)
    }
    
    func downloadFile(file: STLibrary.File) {
        STApplication.shared.downloaderManager.fileDownloader.download(files: [file])
    }
        
}


extension STFileViewerVM: IProviderDelegate {
        
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.snapshot = snapshot
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.delegate?.fileViewerVM(didUpdateedData: weakSelf)
        }
        
    }

}
