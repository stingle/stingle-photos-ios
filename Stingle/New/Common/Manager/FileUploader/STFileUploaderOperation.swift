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
    func fileUploaderOperation(didEndSucces operation: STFileUploader.Operation, file: STLibrary.File, spaceUsed: STDBUsed)
    
}

extension STFileUploader {
    
    class Operation: STOperation<STLibrary.File> {
        
        private weak var delegate: STFileUploaderOperationDelegate?
        private let uploadWorker = STUploadWorker()
        private weak var networkOperation: STUploadNetworkOperation<STResponse<STDBUsed>>?
        
        private(set) var uploadFile: IUploadFile!
        private(set) var libraryFile: STLibrary.File?
        
        init(file: IUploadFile, delegate: STFileUploaderOperationDelegate) {
            self.uploadFile = file
            self.delegate = delegate
            super.init(success: nil, failure: nil, progress: nil)
        }
        
        init(file: STLibrary.File, delegate: STFileUploaderOperationDelegate) {
            self.delegate = delegate
            self.libraryFile = file
            super.init(success: nil, failure: nil, progress: nil)
        }
        
        override func resume() {
            super.resume()
            self.delegate?.fileUploaderOperation(didStart: self)
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
        }
                
        //MARK: - Private
        
        private func upload(file: IUploadFile) {
            file.requestData { [weak self] (info) in
                self?.continueOperation(with: info)
            } failure: { [weak self] (error) in
                self?.responseFailed(error: error)
            }
        }
        
        private func upload(file: STLibrary.File) {
            self.continueOperation(with: file)
        }
        
        private func continueOperation(with info: UploadFileInfo) {
            var fileType: STHeader.FileType!
            switch info.fileType {
            case .image:
                fileType = .image
            case .video:
                fileType = .video
            default:
                self.responseFailed(error: UploaderError.phAssetNotValid)
                return
            }
            guard let localThumbsURL = STApplication.shared.fileSystem.localThumbsURL, let localOreginalsURL = STApplication.shared.fileSystem.localOreginalsURL else {
                self.responseFailed(error: UploaderError.fileSystemNotValid)
                return
            }
            do {
                let encryptedFileInfo = try STApplication.shared.crypto.createEncryptedFile(oreginalUrl: info.oreginalUrl, thumbImage: info.thumbImage, fileType: fileType, duration: info.duration, toUrl: localOreginalsURL, toThumbUrl: localThumbsURL, fileSize: info.fileSize)
                self.continueOperation(with: encryptedFileInfo, info: info)
            } catch {
                self.responseFailed(error: UploaderError.error(error: error))
            }
        }
                
        private func continueOperation(with encryptedFileInfo: (fileName: String, thumbUrl: URL, originalUrl: URL, headers: String), info: UploadFileInfo) {
            let version = "\(STCrypto.Constants.CurrentFileVersion)"
            let dateCreated = info.creationDate ?? Date()
            let dateModified = info.modificationDate ?? Date()
            
            do {
                let file = try STLibrary.File(file: encryptedFileInfo.fileName, version: version, headers: encryptedFileInfo.headers, dateCreated: dateCreated, dateModified: dateModified, isRemote: false)
                self.continueOperation(with: file)
            } catch {
                self.responseFailed(error: UploaderError.error(error: error), file: nil)
            }
        }
        
        private func continueOperation(with file: STLibrary.File) {
            self.delegate?.fileUploaderOperation(didStartUploading: self, file: file)
            let dbInfo = STApplication.shared.dataBase.dbInfoProvider.dbInfo
            guard let spaceQuota = dbInfo.spaceQuota, let spaceUsed = dbInfo.spaceUsed, Double(spaceUsed) ?? 0 < Double(spaceQuota) ?? 0 else {
                self.responseFailed(error: UploaderError.wrongStorageSize, file: file)
                return
            }
            self.networkOperation = self.uploadWorker.upload(file: file) { [weak self] (result) in
                self?.continueOperation(didUpload: file, spaceUsed: result)
            } progress: { [weak self] (progress) in
                self?.responseProgress(result: progress, file: file)
            } failure: { [weak self] (error) in
                self?.responseFailed(error: error, file: file)
            }
        }
        
        private func continueOperation(didUpload file: STLibrary.File, spaceUsed: STDBUsed) {
            
            let oldFileThumbUrl = file.fileThumbUrl
            let oldFileOreginalUrl = file.fileoreginalUrl
            file.isRemote = true
            
            let newFileThumbUrl = file.fileThumbUrl
            let newFileOreginalUrl = file.fileoreginalUrl
            
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
            
            self.responseSucces(result: file, spaceUsed: spaceUsed)
        }
        
        private func responseSucces(result: STLibrary.File, spaceUsed: STDBUsed) {
            super.responseSucces(result: result)
            self.delegate?.fileUploaderOperation(didEndSucces: self, file: result, spaceUsed: spaceUsed)
        }

        private func responseProgress(result: Progress, file: STLibrary.File) {
            super.responseProgress(result: result)
            self.delegate?.fileUploaderOperation(didProgress: self, progress: result, file: file)
        }

        private func responseFailed(error: IError, file: STLibrary.File?) {
            super.responseFailed(error: error)
            self.delegate?.fileUploaderOperation(didEndFailed: self, error: error, file: file)
        }

    }
    
}
