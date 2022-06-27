//
//  STAddMembersShearedAlbumVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/1/21.
//

import Foundation

class STSharedMembersVM {
    
    let contactProvider = STApplication.shared.dataBase.contactProvider
    let membersIDS: [String]
    let contactWorker = STContactWorker()
    let albumWorker = STAlbumWorker()
    
    init(shearedType: STSharedMembersVC.ShearedType) {
        switch shearedType {
        case .album(let album):
            self.membersIDS = album.members?.components(separatedBy: ",") ?? [String]()
        case .files(_):
            self.membersIDS = [String]()
        case .albumFiles:
            self.membersIDS = [String]()
        }
    }
    
    func searcchContact(text: String) -> [STContact] {
        let predicate = NSPredicate(format: "email CONTAINS[c] %@ && NOT \(#keyPath(STCDContact.userId)) IN %@", text, self.membersIDS)
        let result = self.contactProvider.fetchObjects(predicate: predicate)
        return result
    }
    
    func getContacts(contactsIds: [String]) -> [STContact] {
        let result: [STContact] = self.contactProvider.fetchObjects(identifiers: contactsIds)
        return result
    }
    
    func getAlbumContacts(album: STLibrary.Album) -> [STContact] {
        let membersIDS = album.members?.components(separatedBy: ",") ?? [String]()
        let result = self.getContacts(contactsIds: membersIDS)
        return result
    }
    
    func getAllContact() -> [STContact] {
        let predicate = NSPredicate(format: "NOT \(#keyPath(STCDContact.userId)) IN %@", self.membersIDS)
        let result = self.contactProvider.fetchObjects(predicate: predicate)
        return result
    }
    
    func addContact(by email: String, success: @escaping ((_ contact: STContact) -> Void), failure: @escaping ((_ error: IError) -> Void)) {
        guard STApplication.shared.dataBase.userProvider.user?.email != email else {
            failure(SharedMembersError.addingCurrentUserMail)
            return
        }
        self.contactWorker.addContact(email: email) { contact in
            success(contact)
        } failure: { error in
            failure(error)
        }
    }
    
    func addAlbumMember(album: STLibrary.Album, membersIDS: [String], result: @escaping ((_ error: IError?) -> Void)) {
        let newContacts = self.getContacts(contactsIds: membersIDS)
        let oldContacts = self.getAlbumContacts(album: album)
        var contacts = oldContacts
        contacts.append(contentsOf: newContacts)
        
        self.albumWorker.resetAlbumMembers(album: album, contacts: contacts) { _ in
            result(nil)
        } failure: { error in
            result(error)
        }
    }
    
}


extension STSharedMembersVM {
    
    enum SharedMembersError: IError {
        case addingCurrentUserMail
        case contactListIsEmpty
        
        var message: String {
            switch self {
            case .addingCurrentUserMail:
                return "sorry_you_cant_add_yourself".localized
            case .contactListIsEmpty:
                return "share_empty_recipient_list".localized
            }
           
        }
    }
    
    
}
