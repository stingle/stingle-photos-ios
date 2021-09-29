//
//  STAccountVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/27/21.
//

import Foundation

class STAccountVM {
    
    private let authWorker = STAuthWorker()
    
    func getUser() -> STUser? {
        return STApplication.shared.utils.user()
    }
    
    func removeBackcupKeys(completion: @escaping (IError?) -> Void) {
        self.authWorker.removeBackcupKeys { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    func addBackcupKeys(password: String, completion: @escaping (IError?) -> Void) {
        do {
            let _ = try STApplication.shared.crypto.getPrivateKey(password: password)
        } catch {
            completion(STError.passwordNotValied)
            return
        }
        self.authWorker.addBackcupKeys(password: password) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    func validatePassword(_ password: String, completion: @escaping (IError?) -> Void) {
        do {
            let _ = try STApplication.shared.crypto.getPrivateKey(password: password)
            completion(nil)
        } catch {
            completion(STError.passwordNotValied)
            return
        }
    }
    
    func deleteAccount(password: String, completion: @escaping (IError?) -> Void) {
        self.authWorker.deleteAccount(password: password) { _ in
            completion(nil)
        } failure: { error in
            completion(error)
        }
    }
    
    
}
