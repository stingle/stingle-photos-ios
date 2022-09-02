//
//  STBackupPhraseVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/14/21.
//

import Foundation
import UIKit
import StingleRoot

class STBackupPhraseVM {
    
    func getBackupPhrase(password: String?, success: @escaping (String) -> Void, failure: @escaping (IError) -> Void) {
        
        guard let password = password, !password.isEmpty else {
            failure(BackupPhraseError.passwordIsNil)
            return
        }
        
        guard let key = STKeyManagement.key else {
            failure(STError.unknown)
            return
        }
        
        do {
            _ = try STApplication.shared.crypto.getPrivateKeyForExport(password: password)
            let mnemonicString = try STMnemonic.mnemonicString(from: key)
            success(mnemonicString)
        } catch {
            failure(STError.error(error: error))
        }
    }
    
    func copy(backupPhrase: String?) {
        UIPasteboard.general.string = backupPhrase
    }
    
}


extension STBackupPhraseVM {
    
    enum BackupPhraseError: IError {
                
        case passwordIsNil

        var message: String {
            switch self {
            case .passwordIsNil:
                return "error_empty_password".localized
            }
        }
    }
    
}
