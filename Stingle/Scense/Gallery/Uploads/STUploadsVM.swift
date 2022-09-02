//
//  STUploadsVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/24/21.
//

import Foundation
import StingleRoot

protocol STUploadsVMDelegate: AnyObject {
    func uploadsVM(didUpdateFiles uploadsVM: STUploadsVM, uploadFiles: [ILibraryFile], progresses: [String: Progress])
    func uploadsVM(didUpdateProgress uploadsVM: STUploadsVM, for files: [ILibraryFile], uploadFiles: [ILibraryFile], progresses: [String: Progress])
}

class STUploadsVM {
    
    weak var delegate: STUploadsVMDelegate?
    private let uploader = STApplication.shared.uploader
    
    private var progresses = [String: Progress]()
    private var uploadFiles = [ILibraryFile]()
    
    init() {
        self.updateFiles(files: [])
        self.uploader.addListener(self)
    }
    
    private func updateFiles(files: [ILibraryFile]) {
        self.uploader.getProgress { [weak self] progresses, uploadingFiles in
            guard let weakSelf = self else { return }
            weakSelf.update(progresses: progresses, files: uploadingFiles)
            weakSelf.didUpdateFiles(uploadFiles: weakSelf.uploadFiles, progresses: weakSelf.progresses)
        }
    }
    
    private func progressFiles(files: [ILibraryFile]) {
        self.uploader.getProgress { [weak self] progresses, uploadingFiles in
            guard let weakSelf = self else { return }
            let hasChanges = weakSelf.update(progresses: progresses, files: uploadingFiles)
            if hasChanges {
                weakSelf.didUpdateFiles(uploadFiles: weakSelf.uploadFiles, progresses: weakSelf.progresses)
            } else {
                weakSelf.didUpdateProgress(files: files, uploadFiles: weakSelf.uploadFiles, progresses: weakSelf.progresses)
            }
        }
    }
    
    @discardableResult
    private func update(progresses: [String: Progress], files: [ILibraryFile]) -> Bool {
        var hasChanges = false
        self.uploadFiles = files.sorted(by: { file1, file2 in
            let d1 = progresses[file1.identifier]?.startedDate?.timeIntervalSinceNow ?? .zero
            let d2 = progresses[file2.identifier]?.startedDate?.timeIntervalSinceNow ?? .zero
            if !hasChanges {
                if (self.progresses[file1.identifier] !=  progresses[file1.identifier]) || (self.progresses[file2.identifier] != progresses[file2.identifier]) {
                    hasChanges = true
                }
            }
            if d1 == d2 {
                return false
            }
            return d1 < d2
        })
        
        self.progresses = progresses
        return hasChanges
    }

    private func didUpdateFiles(uploadFiles: [ILibraryFile], progresses: [String: Progress]) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.uploadsVM(didUpdateFiles: weakSelf, uploadFiles: weakSelf.uploadFiles, progresses: weakSelf.progresses)
        }
    }
    
    private func didUpdateProgress(files: [ILibraryFile], uploadFiles: [ILibraryFile], progresses: [String: Progress]) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.uploadsVM(didUpdateProgress: weakSelf, for: files, uploadFiles: uploadFiles, progresses: progresses)
        }
    }
}

extension STUploadsVM: IFileUploaderObserver {
    
    func fileUploader(didUpdateProgress uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo, files: [ILibraryFile]) {
        self.progressFiles(files: files)
    }
    
    func fileUploader(didEndSucces uploader: STFileUploader, file: ILibraryFile, uploadInfo: STFileUploader.UploadInfo) {
        self.updateFiles(files: [file])
    }
    
    func fileUploader(didEndFailed uploader: STFileUploader, file: ILibraryFile?, error: IError, uploadInfo: STFileUploader.UploadInfo) {
        guard let file = file else {
            return
        }
        self.updateFiles(files: [file])
    }
    
}
