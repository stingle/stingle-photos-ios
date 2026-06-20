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

//MARK: - async/await

extension STContactWorker {

    public func getContact(email: String) async throws -> STContact {
        try await withCheckedThrowingContinuation { continuation in
            self.getContact(email: email, success: { continuation.resume(returning: $0) },
                            failure: { continuation.resume(throwing: $0) })
        }
    }

    public func addContact(email: String) async throws -> STContact {
        try await withCheckedThrowingContinuation { continuation in
            self.addContact(email: email, success: { continuation.resume(returning: $0) },
                            failure: { continuation.resume(throwing: $0) })
        }
    }

}
