//
//  STContactWorker.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/3/21.
//

import Foundation

public class STContactWorker: STWorker {
    
    public func getContact(email: String, success: @escaping Success<STContact>, failure: Failure?) {
        let request = STContactRequest.getContactBy(email: email)
        self.request(request: request, success: { (response: ContactResponse) in
            success(response.contact)
        }, failure: failure)
    }
    
    public func addContact(email: String, success: @escaping Success<STContact>, failure: Failure?) {
        self.getContact(email: email, success: { contact in
            STApplication.shared.dataBase.contactProvider.add(models: [contact], reloadData: true)
            success(contact)
        }, failure: failure)
    }
    
}

extension STContactWorker {
    
    public struct ContactResponse: Codable {
        let contact: STContact
    }
    
}
