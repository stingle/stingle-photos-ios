//
//  STAccountVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/27/21.
//

import Foundation
import StingleRoot

class STAccountVM {
    
    private let authWorker = STAuthWorker()
    
    func getUser() -> STUser? {
        return STApplication.shared.utils.user()
    }
    
    func removeBackcupKeys(completion: @escaping (IError?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.authWorker.removeBackcupKeys()
                completion(nil)
            } catch {
                completion((error as? IError) ?? STError.error(error: error))
            }
        }
    }

    func addBackcupKeys(password: String, completion: @escaping (IError?) -> Void) {
        do {
            let _ = try STApplication.shared.crypto.getPrivateKey(password: password)
        } catch {
            completion(STError.passwordNotValied)
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.authWorker.addBackcupKeys(password: password)
                completion(nil)
            } catch {
                completion((error as? IError) ?? STError.error(error: error))
            }
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
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.authWorker.deleteAccount(password: password)
                completion(nil)
            } catch {
                completion((error as? IError) ?? STError.error(error: error))
            }
        }
    }
    
    
}
