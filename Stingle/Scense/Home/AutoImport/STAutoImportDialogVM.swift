//
//  STAutoImportDialogVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 1/5/22.
//

import Photos

extension STAutoImportDialogVC {
    
    class ViewModel {
        
        class var isExistDialogInfo: Bool {
            return STAppSettings.current.isExistImportInfo
        }
        
        private var `import` = STAppSettings.current.import
        
        func autoImportDidChange(isOn: Bool, completion: @escaping (ImportDialogError?) -> Void) {
            self.import.isAutoImportEnable = isOn
            STAppSettings.current.import = self.import
            
            guard isOn else {
                completion(nil)
                return
            }
            
            STPHPhotoHelper.checkAndReqauestAuthorization { status in
                if status != .authorized {
                    completion(.phAuthorizationStatus)
                } else {
                    completion(nil)
                }
            }
            
        }
        
        func deleteOriginalFilesAfterAutoImportDidChange(isOn: Bool) {
            self.import.isDeleteOriginalFilesAfterAutoImport = isOn
            STAppSettings.current.import = self.import
        }
        
        func didSelectImporsExistingFilesSwichDidChange(isOn: Bool) {
            self.import.isImporsExistingFiles = isOn
            STAppSettings.current.import = self.import
        }
        
        class func checkAndReqauestAuthorization(completion: @escaping (PHAuthorizationStatus) -> Void) {
            STPHPhotoHelper.checkAndReqauestAuthorization { status in
                completion(status)
            }
        }
                
    }
    
}

extension STAutoImportDialogVC.ViewModel {
    
    class func calculateAutoImportSetupType(completion: @escaping (STAutoImportDialogVC.AutoImportSetupType) -> Void) {
        if self.isExistDialogInfo {
            self.checkAndReqauestAuthorization { status in
                if status == .authorized {
                    completion(.setuped)
                } else {
                    completion(.photoAccessDenied)
                }
            }
        } else {
            completion(.noSetuped)
        }
    }
    
}

extension STAutoImportDialogVC {
    
    enum AutoImportSetupType {
        case setuped
        case noSetuped
        case photoAccessDenied
    }
    
    enum ImportDialogError: IError {
        case phAuthorizationStatus
        
        var message: String {
            switch self {
            case .phAuthorizationStatus:
                return "auto_import_error_photos_access".localized
            }
        }
        
    }
    
}
