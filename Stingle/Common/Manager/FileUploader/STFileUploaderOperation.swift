//
//  STFileUploaderOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/9/21.
//

import Foundation
import UIKit

protocol STFileUploaderOperationDelegate: AnyObject {
    
    func fileUploaderOperation(didStart operation: STFileUploader.Operation)
    func fileUploaderOperation(didStartUploading operation: STFileUploader.Operation, file: STLibrary.File)
    func fileUploaderOperation(didProgress operation: STFileUploader.Operation, progress: Progress, file: STLibrary.File)
    func fileUploaderOperation(didEndFailed operation: STFileUploader.Operation, error: IError, file: STLibrary.File?)
    func fileUploaderOperation(didEndSucces operation: STFileUploader.Operation, file: STLibrary.File, spaceUsed: STDBUsed?)
    
}

extension STFileUploader {
    
    class Operation: STOperation<STLibrary.File> {
        
        private weak var uploaderOperationDelegate: STFileUploaderOperationDelegate?
        private let uploadWorker = STUploadWorker()
        private weak var networkOperation: STUploadNetworkOperation<STResponse<STDBUsed>>?
        
        private(set) var uploadFile: IUploadFile!
        private(set) var libraryFile: STLibrary.File?
        
        init(file: IUploadFile, delegate: STFileUploaderOperationDelegate) {
            self.uploadFile = file
            self.uploaderOperationDelegate = delegate
            super.init(success: nil, failure: nil, progress: nil)
        }
        
        init(file: STLibrary.File, delegate: STFileUploaderOperationDelegate) {
            self.uploaderOperationDelegate = delegate
            self.libraryFile = file
            super.init(success: nil, failure: nil, progress: nil)
        }
        
        override func resume() {
            super.resume()
            self.uploaderOperationDelegate?.fileUploaderOperation(didStart: self)
            if let file = self.libraryFile {
                self.upload(file: file)
            } else if let file = self.uploadFile {
                self.upload(file: file)
            } else {
                self.responseFailed(error: UploaderError.fileNotFound, file: nil)
            }
        }
        
        override func cancel() {
            super.cancel()
            self.networkOperation?.cancel()
            self.responseFailed(error: UploaderError.canceled, file: self.libraryFile)
        }
                
        //MARK: - Private
        
        private func upload(file: IUploadFile) {
            file.requestFile(in: self.delegate?.underlyingQueue) { [weak self] file in
                self?.continueOperation(with: file)
            } failure: { [weak self] error in
                self?.responseFailed(error: error)
            }
        }
        
        private func upload(file: STLibrary.File) {
            self.continueOperation(with: file)
        }
        
        private func continueOperation(with file: STLibrary.File) {
            self.uploaderOperationDelegate?.fileUploaderOperation(didStartUploading: self, file: file)
            let dbInfo = STApplication.shared.dataBase.dbInfoProvider.dbInfo
            
            guard let spaceQuota = dbInfo.spaceQuota, let spaceUsed = dbInfo.spaceUsed, Double(spaceUsed) ?? 0 < Double(spaceQuota) ?? 0 else {
                self.responseFailed(error: UploaderError.wrongStorageSize, file: file)
                return
            }
            
            guard self.canUploadFile() else {
                self.responseSucces(result: file, spaceUsed: nil)
                return
            }
                        
            self.networkOperation = self.uploadWorker.upload(file: file) { [weak self] (result) in
                self?.continueOperation(didUpload: file, spaceUsed: result)
            } progress: { [weak self] (progress) in
                self?.responseProgress(result: progress, file: file)
            } failure: { [weak self] (error) in
                guard !error.isCancelled else {
                    return
                }
                self?.responseFailed(error: error, file: file)
            }
        }
        
        private func continueOperation(didUpload file: STLibrary.File, spaceUsed: STDBUsed) {
            
            guard STApplication.shared.isFileSystemAvailable else {
                self.responseFailed(error: UploaderError.fileSystemNotValid, file: file)
                return
            }
            
            let oldFileThumbUrl = file.fileThumbUrl
            let oldFileOreginalUrl = file.fileOreginalUrl
            file.isRemote = true
            
            let newFileThumbUrl = file.fileThumbUrl
            let newFileOreginalUrl = file.fileOreginalUrl
            
            if let old = oldFileThumbUrl, let new = newFileThumbUrl {
                do {
                    try STApplication.shared.fileSystem.move(file: old, to: new)
                } catch  {
                    self.responseFailed(error: UploaderError.error(error: error), file: file)
                    return
                }
            }
            
            if let old = oldFileOreginalUrl, let new = newFileOreginalUrl {
                do {
                    try STApplication.shared.fileSystem.move(file: old, to: new)
                } catch  {
                    self.responseFailed(error: UploaderError.error(error: error), file: file)
                    return
                }
            }
            
            if let fileOreginalUrl = newFileOreginalUrl {
                STApplication.shared.fileSystem.updateUrlDataSize(url: fileOreginalUrl)
            }
            self.responseSucces(result: file, spaceUsed: spaceUsed)
        }
        
        private func responseSucces(result: STLibrary.File, spaceUsed: STDBUsed?) {
            self.uploaderOperationDelegate?.fileUploaderOperation(didEndSucces: self, file: result, spaceUsed: spaceUsed)
            super.responseSucces(result: result)
        }

        private func responseProgress(result: Progress, file: STLibrary.File) {
            self.uploaderOperationDelegate?.fileUploaderOperation(didProgress: self, progress: result, file: file)
            super.responseProgress(result: result)
        }

        private func responseFailed(error: IError, file: STLibrary.File?) {
            self.uploaderOperationDelegate?.fileUploaderOperation(didEndFailed: self, error: error, file: file)
            super.responseFailed(error: error)
        }
        
        private func canUploadFile() -> Bool {
            return STApplication.shared.utils.canUploadFile()
        }

    }
    
}
