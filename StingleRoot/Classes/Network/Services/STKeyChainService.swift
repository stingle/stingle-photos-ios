//
//  STKeyChainService.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/19/21.
//

import KeychainSwift

class STKeyChainService {
    
    private let keyChain = KeychainSwift()
    
    var passwordKey: String? {
        set {
            self.set(value: newValue, for: .passwordKey)
        } get {
            return self.value(for: .passwordKey)
        }
    }
    
    //MARK: - Public methods
    
    func deleteAll() {
        KeyChainKey.allCases.forEach { key in
            self.keyChain.delete(key.rawValue)
        }
    }
    
    //MARK: - Private methods
    
    private func set(value: String?, for key: KeyChainKey) {
        guard let value = value else {
            self.keyChain.delete(key.rawValue)
            return
        }
        self.keyChain.set(value, forKey: key.rawValue)
    }
    
    private func value(for key: KeyChainKey) -> String? {
        return self.keyChain.get(key.rawValue)
    }
    
}

private extension STKeyChainService {
    
    enum KeyChainKey: String, CaseIterable {
        case passwordKey = "PasswordKey"
    }
    
}
