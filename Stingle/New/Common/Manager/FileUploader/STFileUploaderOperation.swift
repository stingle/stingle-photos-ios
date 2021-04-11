//
//  STFileUploaderOperation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/9/21.
//

import Foundation
import UIKit

protocol STFileUploaderOperationDelegate: class {
    
    func fileUploaderOperation(didStart operation: STFileUploader.Operation)
    func fileUploaderOperation(didStartUploading operation: STFileUploader.Operation, file: STLibrary.File)
    func fileUploaderOperation(didProgress operation: STFileUploader.Operation, progress: Progress, file: STLibrary.File)
    func fileUploaderOperation(didEndFailed operation: STFileUploader.Operation, error: IError, file: STLibrary.File?)
    func fileUploaderOperation(didEndSucces operation: STFileUploader.Operation, file: STLibrary.File)
    
}

extension STFileUploader {
    
    class Operation: STOperation<STLibrary.File> {
        
        private weak var delegate: STFileUploaderOperationDelegate?
        
        let file: IUploadFile
        
        init(file: IUploadFile, delegate: STFileUploaderOperationDelegate) {
            self.file = file
            self.delegate = delegate
            super.init(success: nil, failure: nil, progress: nil)
        }
        
        override func resume() {
            super.resume()
            self.delegate?.fileUploaderOperation(didStart: self)
            self.file.requestData { [weak self] (info) in
                self?.continueOperation(with: info)
            } failure: { [weak self] (error) in
                self?.responseFailed(error: error)
            }
        }
                
        //MARK: - Private
        
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
            
            
            
        }
        
        private func responseSucces(result: STLibrary.File) {
            super.responseSucces(result: result)
            self.delegate?.fileUploaderOperation(didEndSucces: self, file: result)
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
