//
//  STImportVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 1/5/22.
//

import Foundation

extension STImportVC {
    
    class ViewModel {
        
        lazy var `import`: STAppSettings.Import = {
            return STAppSettings.current.import
        }()
        
        lazy var auotImporter: STImporter.AuotImporter = {
            return STApplication.shared.auotImporter
        }()
        
        func update(autoImportEnable isOn: Bool, completion: @escaping (ImportError?) -> Void) {
            
            guard isOn else {
                self.import.isAutoImportEnable = isOn
                STAppSettings.current.import = self.import
                completion(nil)
                return
            }
            
            STPHPhotoHelper.checkAndReqauestAuthorization { [weak self] status in
                guard let weakSelf = self else { return }
                if status == .authorized {
                    weakSelf.auotImporter.resetImportDate(date: .currentDate, startImport: false) {
                        weakSelf.import.isAutoImportEnable = isOn
                        STAppSettings.current.import = weakSelf.import
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } else {
                    completion(ImportError.phAuthorizationStatus)
                }
            }
        }
        
        func update(autoImportDeleteFiles isOn: Bool, completion: @escaping (ImportError?) -> Void) {
            self.import.isDeleteOriginalFilesAfterAutoImport = isOn
            STAppSettings.current.import = self.import
            completion(nil)
        }
        
        func update(manualImportDeleteFilesType: STAppSettings.Import.ManualImportDeleteFilesType, completion: @escaping (ImportError?) -> Void) {
            self.import.manualImportDeleteFilesType = manualImportDeleteFilesType
            STAppSettings.current.import = self.import
            completion(nil)
        }
        
        func resetImportDate() {
            self.auotImporter.resetImportDate(date: .setupDate, startImport: true)
        }
        
    }
    
}

extension STImportVC {
    
    enum ImportError {
        case phAuthorizationStatus
        var message: String {
            switch self {
            case .phAuthorizationStatus:
                return "auto_import_error_photos_access".localized
            }
        }
    }
    
}


