//
//  STUploadsVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/24/21.
//

import Foundation

protocol STUploadsVMDelegate: class {
    func uploadsVM(didUpdateFiles uploadsVM: STUploadsVM, uploadFiles: [STLibrary.File], progresses: [String: Progress])
    func uploadsVM(didUpdateProgress uploadsVM: STUploadsVM, for files: [STLibrary.File])
}

class STUploadsVM {
    
    weak var delegate: STUploadsVMDelegate?
    private let uploader = STApplication.shared.uploader
    
    private(set) var progresses = [String: Progress]()
    private(set) var uploadFiles = [STLibrary.File]()
    
    init() {
        self.updateFiles(files: [])
        self.uploader.addListener(self)
    }
    
    private func updateFiles(files: [STLibrary.File]) {
        if self.uploader.uploadingFiles.count != self.uploadFiles.count {
            self.uploadFiles = self.uploader.uploadingFiles
            self.progresses = self.uploader.progresses
            self.didUpdateFiles()
        } else {
            self.uploadFiles = self.uploader.uploadingFiles
            self.progresses = self.uploader.progresses
            self.didUpdateProgress(files: files)
        }
    }
    
    private func didEndUploading(file: STLibrary.File) {
        self.uploadFiles = self.uploader.uploadingFiles
        self.progresses = self.uploader.progresses
        self.didUpdateFiles()
    }
    
    private func didUpdateFiles() {
        self.delegate?.uploadsVM(didUpdateFiles: self, uploadFiles: self.uploadFiles, progresses: self.progresses)
    }
    
    private func didUpdateProgress(files: [STLibrary.File]) {
        self.delegate?.uploadsVM(didUpdateProgress: self, for: files)
    }
            
}

extension STUploadsVM: IFileUploaderObserver {
    
    func fileUploader(didUpdateProgress uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo, files: [STLibrary.File]) {
        self.updateFiles(files: files)
    }
    
    func fileUploader(didEndSucces uploader: STFileUploader, file: STLibrary.File, uploadInfo: STFileUploader.UploadInfo) {
        self.didEndUploading(file: file)
    }
    
    func fileUploader(didEndFailed uploader: STFileUploader, file: STLibrary.File?, error: IError, uploadInfo: STFileUploader.UploadInfo) {
        guard let file = file else {
            return
        }
        self.didEndUploading(file: file)
    }
    
}
