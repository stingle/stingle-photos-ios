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
    func getMorAction(for file: STLibrary.File) -> [STFileViewerVC.MoreAction]
    
    func selectMore(action: STFileViewerVC.MoreAction, file: STLibrary.File)
    
    func moveInfo(for file: STLibrary.File) -> STMoveAlbumFilesVC.MoveInfo
    
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
        let result = self.dataSource.object(at: indexPath)
        return result
    }
    
    func getIndex(at model: ManagedObject.Model) -> Int? {
        return self.dataSource.indexPath(forObject: model)?.row
    }
    
    //MARK: - IFileViewerVM
    
    func object(at index: Int) -> STLibrary.File? {
        return self.getObject(at: index) as? STLibrary.File
    }
    
    func index(at file: STLibrary.File) -> Int? {
        return self.getIndex(at: file as! ManagedObject.Model)
    }
    
    var countOfItems: Int {
        guard let snapshot = self.snapshot, let section = snapshot.sectionIdentifiers.first else {
            return .zero
        }
        return snapshot.numberOfItems(inSection: section)
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
    
    func getMorAction(for file: STLibrary.File) -> [STFileViewerVC.MoreAction] {
        return [.download]
    }
    
    func removeFileSystemFolder(url: URL) {
        STApplication.shared.fileSystem.remove(file: url)
    }
    
    func downloadFile(file: STLibrary.File) {
        STApplication.shared.downloaderManager.fileDownloader.download(files: [file])
    }
    
    func selectMore(action: STFileViewerVC.MoreAction, file: STLibrary.File) {
        switch action {
        case .download:
            self.downloadFile(file: file)
        default:
            break
        }
    }
    
    func moveInfo(for file: STLibrary.File) -> STMoveAlbumFilesVC.MoveInfo {
        return .files(files: [file])
    }
        
}


extension STFileViewerVM: IProviderDelegate {
        
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.snapshot = snapshot
        self.delegate?.fileViewerVM(didUpdateedData: self)
        
    }

}
