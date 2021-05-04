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
    
    init(shearedType: STSharedMembersVC.ShearedType) {
        switch shearedType {
        case .album(let album):
            self.membersIDS = album.members?.components(separatedBy: ",") ?? [String]()
        case .files(_):
            self.membersIDS = [String]()
        }
    }
    
    func searcchContact(text: String) -> [STContact] {
        let predicate = NSPredicate(format: "email CONTAINS[c] %@ && NOT email IN %@", text, self.membersIDS)
        let result = self.contactProvider.fetchObjects(predicate: predicate)
        return result
    }
    
    func getAllContact() -> [STContact] {
        let predicate = NSPredicate(format: "NOT email IN %@", self.membersIDS)
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
