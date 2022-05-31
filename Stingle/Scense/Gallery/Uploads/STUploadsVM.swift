//
//  STUploadsVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/24/21.
//

import Foundation

protocol STUploadsVMDelegate: AnyObject {
    func uploadsVM(didUpdateFiles uploadsVM: STUploadsVM, uploadFiles: [ILibraryFile], progresses: [String: Progress])
    func uploadsVM(didUpdateProgress uploadsVM: STUploadsVM, for files: [ILibraryFile])
}

class STUploadsVM {
    
    weak var delegate: STUploadsVMDelegate?
    private let uploader = STApplication.shared.uploader
    
    private(set) var progresses = [String: Progress]()
    private(set) var uploadFiles = [ILibraryFile]()
    
    init() {
        self.updateFiles(files: [])
        self.uploader.addListener(self)
    }
    
    private func updateFiles(files: [ILibraryFile]) {
        self.uploader.getProgress { [weak self] progresses, uploadingFiles in
            guard let weakSelf = self else { return }
            if uploadingFiles.count != weakSelf.uploadFiles.count {
                weakSelf.uploadFiles = uploadingFiles
                weakSelf.progresses = progresses
                weakSelf.didUpdateFiles()
            } else {
                weakSelf.uploadFiles = uploadingFiles
                weakSelf.progresses = progresses
                weakSelf.didUpdateProgress(files: files)
            }
        }
    }
        
    private func didEndUploading(file: ILibraryFile) {
        self.uploader.getProgress { [weak self] progresses, uploadingFiles in
            self?.uploadFiles = uploadingFiles
            self?.progresses = progresses
            self?.didUpdateFiles()
        }
    }
    
    private func didUpdateFiles() {
        
        self.uploadFiles = self.uploadFiles.sorted { f, s in
            let fP = self.progresses[f.identifier]?.fractionCompleted ?? .zero
            let sP = self.progresses[s.identifier]?.fractionCompleted ?? .zero
            return fP > sP
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.uploadsVM(didUpdateFiles: weakSelf, uploadFiles: weakSelf.uploadFiles, progresses: weakSelf.progresses)
        }
    }
    
    private func didUpdateProgress(files: [ILibraryFile]) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.uploadsVM(didUpdateProgress: weakSelf, for: files)
        }
    }
            
}

extension STUploadsVM: IFileUploaderObserver {
    
    func fileUploader(didUpdateProgress uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo, files: [ILibraryFile]) {
        self.updateFiles(files: files)
    }
    
    func fileUploader(didEndSucces uploader: STFileUploader, file: ILibraryFile, uploadInfo: STFileUploader.UploadInfo) {
        self.didEndUploading(file: file)
    }
    
    func fileUploader(didEndFailed uploader: STFileUploader, file: ILibraryFile?, error: IError, uploadInfo: STFileUploader.UploadInfo) {
        guard let file = file else {
            return
        }
        self.didEndUploading(file: file)
    }
    
}
