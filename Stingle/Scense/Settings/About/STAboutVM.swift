//
//  STSTAboutVM.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/28/21.
//

import Foundation
import StingleRoot

extension STAboutVC {
    
    class ViewModel {
        
        func generateDataModel() -> DataModel {
            let version = self.generateVersionSection()
            let legalPolicies = self.generateLegalPolicies()
            return DataModel(section: [version, legalPolicies])
        }
        
        private func generateVersionSection() -> DataModel.Section {
            let appVersion = STApplication.appVersion
            let item = DataModel.PlainItem(type: .version, shouldHighlight: false, title: "version".localized, subTitle: appVersion)
            let header = DataModel.Header(title: "home".localized)
            return DataModel.Section(header: header, items: [item])
        }
        
        private func generateLegalPolicies() -> DataModel.Section {
            let privacyPolicyStr = "privacy_policy".localized
            let termsOfUseStr = "terms_of_use".localized
            
            let privacyPolicy = DataModel.DetailItem(type: .privacyPolicy, shouldHighlight: true, title: privacyPolicyStr)
            let termsOfUse = DataModel.DetailItem(type: .termsOfUse, shouldHighlight: true, title: termsOfUseStr)
            
            let header = DataModel.Header(title: "legal_policies".localized)
            return DataModel.Section(header: header, items: [privacyPolicy, termsOfUse])
        }
        
        
    }
    
}

protocol IAboutVCCellItem {
    var type: STAboutVC.DataModel.ItemType { get }
    var shouldHighlight: Bool { get }
}

extension STAboutVC {
    
    struct DataModel {
        
        let section: [Section]
        
        struct Header {
            let title: String
        }
        
        struct Section {
            let header: Header?
            let items: [IAboutVCCellItem]
        }
        
        enum ItemType {
            
            case version
            case privacyPolicy
            case termsOfUse
            
            var identify: ItemIdentify {
                switch self {
                case .version:
                    return .plain
                case .privacyPolicy:
                    return .detail
                case .termsOfUse:
                    return .detail
                }
            }
        }
        
        enum ItemIdentify: CaseIterable {
            case plain
            case detail
            
            var reuse: String {
                switch self {
                case .plain:
                    return "plain"
                case .detail:
                    return "detail"
                }
            }
            
            var nibName: String {
                switch self {
                case .plain:
                    return "STAboutPlainTableViewCell"
                case .detail:
                    return "STAboutDetailTableViewCell"
                }
            }
            
        }
        
        struct DetailItem: IAboutVCCellItem {
            var type: STAboutVC.DataModel.ItemType
            let shouldHighlight: Bool
            let title: String
        }
        
        struct PlainItem: IAboutVCCellItem {
            var type: STAboutVC.DataModel.ItemType
            let shouldHighlight: Bool
            let title: String
            let subTitle: String?
        }
        
    }
    
}
