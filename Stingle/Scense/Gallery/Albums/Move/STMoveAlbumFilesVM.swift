//
//  STMoveAlbumFilesVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/8/21.
//

import Foundation
import StingleRoot

class STMoveAlbumFilesVM {
    
    private let albumWorker = STAlbumWorker()
    private let fileWorker = STFileWorker()
    
    private(set) var isDeleteFilesLastValue: Bool {
        set {
            STAppSettings.current.isDeleteFilesWhenMoving = newValue
        } get {
            return STAppSettings.current.isDeleteFilesWhenMoving
        }
    }
    
    func moveToAlbum(toAlbum: STLibrary.Album, files: [STLibrary.GaleryFile], isDeleteFiles: Bool, result: @escaping (_ result: IError?) -> Void) {
        self.isDeleteFilesLastValue = isDeleteFiles
        let isMoving = self.isDeleteFilesLastValue
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.moveFiles(files: files, toAlbum: toAlbum, isMoving: isMoving)
                result(nil)
            } catch {
                result((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
    
    func moveToAlbum(fromAlbum: STLibrary.Album, toAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isDeleteFiles: Bool, result: @escaping (_ result: IError?) -> Void) {
        self.isDeleteFilesLastValue = isDeleteFiles
        let isMoving = self.isDeleteFilesLastValue && fromAlbum.isOwner
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.moveFiles(fromAlbum: fromAlbum, toAlbum: toAlbum, files: files, isMoving: isMoving, reloadDBData: true)
                result(nil)
            } catch {
                result((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
    func moveFilesToGallery(fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isDeleteFiles: Bool, result: @escaping (_ result: IError?) -> Void) {
        self.isDeleteFilesLastValue = isDeleteFiles
        let isMoving = self.isDeleteFilesLastValue && fromAlbum.isOwner
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.moveFilesToGallery(fromAlbum: fromAlbum, files: files, isMoving: isMoving)
                result(nil)
            } catch {
                result((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
    func createAlbum(name: String, fromAlbum: STLibrary.Album, files: [STLibrary.AlbumFile], isDeleteFiles: Bool, result: @escaping (_ result: IError?) -> Void) {
        self.isDeleteFilesLastValue = isDeleteFiles
        let isMoving = self.isDeleteFilesLastValue && fromAlbum.isOwner
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.createAlbum(name: name, fromAlbum: fromAlbum, files: files, isMoving: isMoving)
                result(nil)
            } catch {
                result((error as? IError) ?? STError.error(error: error))
            }
        }
    }

    func createAlbum(name: String, result: @escaping (_ result: IError?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.createAlbum(name: name)
                result(nil)
            } catch {
                result((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
}
