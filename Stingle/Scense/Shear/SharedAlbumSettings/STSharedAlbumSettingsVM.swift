//
//  SharedAlbumSettingsVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/17/21.
//

import Foundation
import StingleRoot

protocol STSharedAlbumSettingsVMDelegate: AnyObject {
    
    func sharedAlbumSettingsVM(albumDidDeleted provider: STSharedAlbumSettingsVM)
    func sharedAlbumSettingsVM(albumDidUpdated provider: STSharedAlbumSettingsVM, album: STLibrary.Album)
    
}

class STSharedAlbumSettingsVM {
    
    private(set) var album: STLibrary.Album
    private let contactProvider = STApplication.shared.dataBase.contactProvider
    private var albumWorker = STAlbumWorker()
    weak var delegate: STSharedAlbumSettingsVMDelegate?
    
    
    init(album: STLibrary.Album) {
        self.album = album
        STApplication.shared.dataBase.albumsProvider.add(self)
    }
    
    func getContacts(contactsIds: [String]) -> [STContact] {
        let result: [STContact] = self.contactProvider.fetchObjects(identifiers: contactsIds)
        return result
    }
    
    func getAlbumContacts() -> [STContact] {
        let membersIDS = self.album.members?.components(separatedBy: ",") ?? [String]()
        let result = self.getContacts(contactsIds: membersIDS)
        return result
    }
    
    func getMembers() -> [STContact] {
        guard var members = self.album.members?.components(separatedBy: ","), !members.isEmpty, let myUser = STApplication.shared.dataBase.userProvider.myUser else {
            return []
        }
        members = members.filter( { $0 != myUser.userId} )
        return STApplication.shared.dataBase.contactProvider.fetchObjects(identifiers: members)
    }
    
    func removeMember(memberID: String, result: @escaping (_ result: IError?) -> Void) {
        let contacts = self.getAlbumContacts()
        let newContacts = contacts.filter( {$0.userId != memberID} )
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.resetAlbumMembers(album: self.album, contacts: newContacts)
                result(nil)
            } catch {
                result((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
    func leaveAlbum(result: @escaping (_ result: IError?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.leaveAlbum(album: self.album)
                result(nil)
            } catch {
                result((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
    func unshareAlbum(result: @escaping (_ result: IError?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.unshareAlbum(album: self.album)
                result(nil)
            } catch {
                result((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
    func updatePermission(permission: STLibrary.Album.Permission, result: @escaping (_ result: IError?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.albumWorker.updatePermission(album: self.album, permission: permission)
                result(nil)
            } catch {
                result((error as? IError) ?? STError.error(error: error))
            }
        }
    }
        
}

extension STSharedAlbumSettingsVM: IDataBaseProviderProviderObserver {
    
    func dataBaseProvider(didDeleted provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {
        guard (((models as? [STLibrary.Album])?.contains(where: { $0.albumId == self.album.albumId })) != nil) else {
            return
        }
        self.delegate?.sharedAlbumSettingsVM(albumDidDeleted: self)
    }
    
    func dataBaseProvider(didUpdated provider: IDataBaseProviderProvider, models: [IDataBaseProviderModel]) {
        guard let albums = (models as? [STLibrary.Album]), let album = albums.first(where: { $0.albumId == self.album.albumId}) else {
            return
        }
        self.album = album
        self.delegate?.sharedAlbumSettingsVM(albumDidUpdated: self, album: album)
    }
    
}
