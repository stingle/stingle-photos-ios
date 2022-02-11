//
//  STFileWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/9/21.
//

import Foundation

class STFileWorker: STWorker {
    
    func moveFilesToTrash(files: [STLibrary.File], reloadDBData: Bool = true, success: Success<STEmptyResponse>?, failure: Failure?) {
        
        //TODO: - khoren
        
        guard !files.isEmpty else {
            success?(STEmptyResponse())
            return
        }
        
        let uploader = STApplication.shared.uploader
        
        do {
            var trashFiles = [STLibrary.TrashFile]()
            for file in files {
                let file = try STLibrary.TrashFile(file: file.file, version: file.version, headers: file.headers, dateCreated: file.dateCreated, dateModified: file.dateModified, isRemote: file.isRemote, managedObjectID: file.managedObjectID)
                trashFiles.append(file)
                uploader.cancelUploadIng(for: file)
            }
            
            let request = STFilesRequest.moveToTrash(files: files)
            let galleryProvider = STApplication.shared.dataBase.galleryProvider
            let trashProvider = STApplication.shared.dataBase.trashProvider
                        
            self.request(request: request, success: { (response: STEmptyResponse) in
                galleryProvider.delete(models: files, reloadData: reloadDBData)
                trashProvider.add(models: trashFiles, reloadData: reloadDBData)
                success?(response)
            }, failure: failure)
            
        } catch {
            failure?(WorkerError.error(error: error))
        }
        
    }
    
    func deleteFiles(files: [STLibrary.TrashFile], success: Success<STEmptyResponse>?, failure: Failure?) {
        guard !files.isEmpty else {
            success?(STEmptyResponse())
            return
        }
        
        let trashProvider = STApplication.shared.dataBase.trashProvider
        let request = STFilesRequest.delete(files: files)
        
        STApplication.shared.uploader.cancelUploadIng(for: files)
        
        self.request(request: request, success: { (response: STEmptyResponse) in
            trashProvider.delete(models: files, reloadData: true)
            STApplication.shared.utils.deleteFilesIfNeeded(files: files, complition: nil)
            success?(response)
        }, failure: failure)
        
    }
    
    func moveToGalery(files: [STLibrary.TrashFile], success: Success<STEmptyResponse>?, failure: Failure?) {
        guard !files.isEmpty else {
            success?(STEmptyResponse())
            return
        }
        
        let remoteFiles = files.filter({ $0.isRemote })
        let trashProvider = STApplication.shared.dataBase.trashProvider
        let galleryProvider = STApplication.shared.dataBase.galleryProvider
        
        STApplication.shared.uploader.cancelUploadIng(for: files)
        
        guard !remoteFiles.isEmpty else {
            trashProvider.delete(models: files, reloadData: true)
            galleryProvider.add(models: files, reloadData: true)
            success?(STEmptyResponse())
            return
        }
        
        
        let request = STFilesRequest.moveToGalery(files: remoteFiles)
        
        self.request(request: request, success: { (response: STEmptyResponse) in
            trashProvider.delete(models: files, reloadData: true)
            galleryProvider.add(models: files, reloadData: true)
            success?(response)
        }, failure: failure)
        
    }
        
}
