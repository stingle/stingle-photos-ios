//
//  STAlbumsVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import Foundation
import StingleRoot

class STAlbumsVM {
    
    private let syncManager = STApplication.shared.syncManager
    private let albumWorker = STAlbumWorker()
    
    func sync() {
        self.syncManager.sync()
    }
    
    func createAlbum(with name: String, compliation: @escaping (_ error: IError?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.createAlbum(name: name)
                compliation(nil)
            } catch {
                compliation((error as? IError) ?? STError.error(error: error))
            }
        }
    }

    func deleteAlbum(album: STLibrary.Album, compliation: @escaping (_ error: IError?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.deleteAlbumWithFiles(album: album)
                compliation(nil)
            } catch {
                compliation((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
        
}
