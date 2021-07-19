//
//  STBiometricAuthenticationServices.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/20/21.
//

import LocalAuthentication

class STBiometricAuthServices {
            
    //MARK: - Public methods
    
    func onBiometricAuth() {
        
    }
    
    func unlockApp(failure:  @escaping (_ error: IError) -> Void) {
        
        self.checkBiometry({
            
            self.readPassword({
                
              print("")
                
                
            }, failure)
            
        }, failure)
        
    }
    
    //MARK: - Private methods
    
    private func getBioSecAccessControl() -> SecAccessControl? {
        var error: Unmanaged<CFError>?
        let access: SecAccessControl? = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .biometryCurrentSet,  &error)
        return access
    }
    
    private func checkBiometry(_ success: @escaping () -> Void, _ failure:  @escaping (_ error: IError) -> Void) {
        let bioState = self.state
       
        guard bioState != .notAvailable else {
            failure(AuthError.stateNotAvailable)
            return
        }
        
        if bioState == .locked {
            let authContext = LAContext()
            authContext.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: "", reply: { (successPolicy, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        failure(AuthError.error(error: error))
                    } else {
                        success()
                    }
                }
            })
        } else {
            success()
        }
    }
    
    private func readPassword(_ success: @escaping () -> Void, _ failure:  @escaping (_ error: IError) -> Void) {
        
        guard let accessControl = self.getBioSecAccessControl() else {
            failure(AuthError.unknown)
            return
        }
        let authContext = LAContext()
        authContext.evaluateAccessControl(accessControl, operation: .useItem, localizedReason: "Hello") { (successPolicy, error) in
            
            DispatchQueue.main.async {
                if let error = error {
                    failure(AuthError.error(error: error))
                } else {
                    success()
                }
            }

        }
        
    }
    
}


extension STBiometricAuthServices {
    
    var state: State {
        let authContext = LAContext()
        var error: NSError?
        let biometryAvailable = authContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if let laError = error as? LAError, laError.code == LAError.Code.biometryLockout {
            return .locked
        }
        return biometryAvailable ? .available : .notAvailable
    }
    
    enum State {
        case available
        case locked
        case notAvailable
    }
    
    enum AuthError: IError {
        
        case error(error: Error)
        case stateNotAvailable
        case unknown
        
        var message: String {
            switch self {
            case .error(let error):
                if let error = error as? IError {
                    return error.message
                }
                return error.localizedDescription
            case .stateNotAvailable:
                return "stateNotAvailable"
            case .unknown:
                return "error_unknown_error".localized
            }
        }
    }
    
    
}
