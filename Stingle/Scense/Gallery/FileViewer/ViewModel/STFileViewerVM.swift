//
//  STFileViewerVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/18/21.
//

import UIKit
import StingleRoot

protocol IFileViewerVM {
    
    var delegate: STFileViewerVMDelegate? { get set }
    var countOfItems: Int { get }
    
    func object(at index: Int) -> STLibrary.FileBase?
    func index(at file: STLibrary.FileBase) -> Int?
    
    func deleteFile(file: STLibrary.FileBase, completion: @escaping (_ result: IError?) -> Void)
    
    func getDeleteFileMessage(file: STLibrary.FileBase) -> String
    func removeFileSystemFolder(url: URL)
    func downloadFile(file: STLibrary.FileBase)
    
    func getAction(for file: STLibrary.FileBase) -> [STFileViewerVC.ActionType]
    func getMorAction(for file: STLibrary.FileBase) -> [STFileViewerVC.MoreAction]
    func getShearedType(for file: STLibrary.FileBase) -> STSharedMembersVC.ShearedType
    
    func selectMore(action: STFileViewerVC.MoreAction, file: STLibrary.FileBase)
    func moveInfo(for file: STLibrary.FileBase) -> STMoveAlbumFilesVC.MoveInfo
    func editVM(for file: STLibrary.FileBase) -> IFileEditVM
    
}

protocol STFileViewerVMDelegate: AnyObject {
    func fileViewerVM(didUpdateedData fileViewerVM: IFileViewerVM)
}

class STFileViewerVM<File: STLibrary.FileBase> where File: ICDSynchConvertable {
        
    private let dataSource: STDataBase.DataSource<File>
    private var snapshot: NSDiffableDataSourceSnapshotReference?
    
    weak var delegate: STFileViewerVMDelegate? {
        didSet {
            self.dataSource.reloadData()
        }
    }
    
    init(dataSource: STDataBase.DataSource<File>) {
        self.dataSource = dataSource
        self.dataSource.delegate = self
    }
    
    func getObject(at index: Int) -> File? {
        guard index < self.countOfItems, index >= .zero else {
            return nil
        }
        let indexPath = IndexPath(item: index, section: .zero)
        let result = self.dataSource.object(at: indexPath)
        return result
    }
    
    func getIndex(at model: File) -> Int? {
        return self.dataSource.indexPath(forObject: model)?.row
    }
    
    //MARK: - IFileViewerVM
    
    func object(at index: Int) -> File? {
        return self.getObject(at: index)
    }
    
    func index(at file: File) -> Int? {
        return self.getIndex(at: file)
    }
    
    var countOfItems: Int {
        guard let snapshot = self.snapshot, let section = snapshot.sectionIdentifiers.first else {
            return .zero
        }
        return snapshot.numberOfItems(inSection: section)
    }
    
    func deleteFile(file: File, completion: @escaping (_ result: IError?) -> Void) {
        fatalError("this method must be implemented in chile classes")
    }
    
    func getDeleteFileMessage(file: File) -> String {
        fatalError("this method must be implemented in child classes")
    }
    
    func getAction(for file: File) -> [STFileViewerVC.ActionType] {
        fatalError("this method must be implemented in child classes")
    }
    
    func getMorAction(for file: File) -> [STFileViewerVC.MoreAction] {
        return [.download]
    }
    
    func getShearedType(for file: File) -> STSharedMembersVC.ShearedType {
        fatalError("this method must be implemented in child classes")
    }
    
    func removeFileSystemFolder(url: URL) {
        STApplication.shared.fileSystem.remove(file: url)
    }
    
    func downloadFile(file: File) {
        STApplication.shared.downloaderManager.fileDownloader.download(files: [file])
    }
    
    func selectMore(action: STFileViewerVC.MoreAction, file: File) {
        switch action {
        case .download:
            self.downloadFile(file: file)
        default:
            break
        }
    }
    
    func moveInfo(for file: File) -> STMoveAlbumFilesVC.MoveInfo {
        fatalError("this method must be implemented in chile classes")
    }

    func editVM(for file: File) -> IFileEditVM {
        fatalError("this method must be implemented in chile classes")
    }
    
    func getDefaultActions(for file: File) -> [STFileViewerVC.ActionType] {
        var allCasesWithoutEdit = STFileViewerVC.ActionType.allCases.filter({ $0 != .edit })
        guard let originalType = file.decryptsHeaders.file?.fileOreginalType else {
            return allCasesWithoutEdit
        }
        switch originalType {
        case .video:
            return allCasesWithoutEdit
        case .image:
            if file.decryptsHeaders.file?.fileName?.pathExtension.lowercased() != "gif" {
                allCasesWithoutEdit.append(.edit)
            }
            return allCasesWithoutEdit
        }
    }
}

extension STFileViewerVM: IProviderDelegate {
        
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.snapshot = snapshot
        self.delegate?.fileViewerVM(didUpdateedData: self)
    }

}

extension STFileViewerVM: IFileViewerVM {
        
    func object(at index: Int) -> STLibrary.FileBase? {
        let obj: File? = self.object(at: index)
        return obj
    }
    
    func index(at file: STLibrary.FileBase) -> Int? {
        return self.index(at: file as! File)
    }
    
    func deleteFile(file: STLibrary.FileBase, completion: @escaping (IError?) -> Void) {
        return self.deleteFile(file: file as! File, completion: completion)
    }

    func getDeleteFileMessage(file: STLibrary.FileBase) -> String {
        return self.getDeleteFileMessage(file: file as! File)
    }

    func downloadFile(file: STLibrary.FileBase) {
        return self.downloadFile(file: file as! File)
    }

    func getAction(for file: STLibrary.FileBase) -> [STFileViewerVC.ActionType] {
        return self.getAction(for: file as! File)
    }

    func getMorAction(for file: STLibrary.FileBase) -> [STFileViewerVC.MoreAction] {
        return self.getMorAction(for: file as! File)
    }

    func selectMore(action: STFileViewerVC.MoreAction, file: STLibrary.FileBase) {
        return self.selectMore(action: action, file: file as! File)
    }

    func moveInfo(for file: STLibrary.FileBase) -> STMoveAlbumFilesVC.MoveInfo {
        return self.moveInfo(for: file as! File)
    }

    func editVM(for file: STLibrary.FileBase) -> IFileEditVM {
        return self.editVM(for: file as! File)
    }
    
    func getShearedType(for file: STLibrary.FileBase) -> STSharedMembersVC.ShearedType {
        return self.getShearedType(for: file as! File)
    }
    
}

