//
//  STStorageVC+Data.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/20/21.
//

import Foundation

protocol IStorageItemModel {
    var identifier: String { get }
}

extension STStorageVC {
    
    struct ProductGroup: CaseIterable, Hashable {
        
        enum Product: String, CaseIterable {
            case gb100 = "100gb"
            case gb300 = "300gb"
            case tb1 = "1tb"
            case tb3 = "3tb"
            case tb5 = "5tb"
            case tb10 = "10tb"
            case tb20 = "20tb"
            
            var localized: String {
                switch self {
                case .gb100:
                    return "100_gb".localized
                case .gb300:
                    return "300_gb".localized
                case .tb1:
                    return "1_tb".localized
                case .tb3:
                    return "3_tb".localized
                case .tb5:
                    return "5_tb".localized
                case .tb10:
                    return "10_tb".localized
                case .tb20:
                    return "20_tb".localized
                }
            }
        }
        
        enum Period: String, CaseIterable {
            case monthly = "monthly"
            case yearly = "yearly"
        }
        
        static var allCases: [ProductGroup] {
            
            let productCasses = Product.allCases
            let periodCasses = Period.allCases
            
            var result = [ProductGroup]()
            productCasses.forEach { product in
                periodCasses.forEach { period in
                    let group = ProductGroup(product: product, period: period)
                    result.append(group)
                }
            }
            return result
        }
        
        static var allIdentifiers: [String] {
            
            let productCasses = Product.allCases
            let periodCasses = Period.allCases
            
            var result = [String]()
            productCasses.forEach { product in
                periodCasses.forEach { period in
                    let identifier = ProductGroup(product: product, period: period).identifier
                    result.append(identifier)
                }
            }
            return result
        }
        
        static func productGroup(for identifier: String) -> ProductGroup? {
            let parts: [String] = identifier.components(separatedBy: "_")
            guard parts.count == 2, let product = Product(rawValue: parts.first!), let period = Period(rawValue: parts.last!) else {
                return nil
            }
            let group = ProductGroup(product: product, period: period)
            return group
        }
        
        
        func hash(into hasher: inout Hasher) {
            return self.identifier.hash(into: &hasher)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.identifier == rhs.identifier
        }
        
        var identifier: String {
            return self.product.rawValue + "_" + self.period.rawValue
        }
        
        let product: Product
        let period: Period
        
    }
}


extension STStorageVC {
        
    struct Section: Hashable {

        enum SectionType: String {
            case bildingInfo = "bildingInfo"
            case product = "product"
        }
        
        let type: SectionType
        let herader: Item?
        let items: [Item]
        
        static func == (lhs: STStorageVC.Section, rhs: STStorageVC.Section) -> Bool {
            return lhs.type == rhs.type && lhs.herader == rhs.herader
        }
        
        func hash(into hasher: inout Hasher) {
            self.type.hash(into: &hasher)
            self.herader.hash(into: &hasher)
        }
        
    }
    
    struct Item: Hashable {
        
        var item: IStorageItemModel
        var reuseIdentifier: ItemReuseIdentifier

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.item.identifier)
        }

        static func == (lhs: Item, rhs: Item) -> Bool {
            return lhs.item.identifier == rhs.item.identifier
        }

    }
    
    enum ItemReuseIdentifier: CaseIterable {
        
        enum Kinde {
            case herader
            case cell
        }
        
        case bildingInfo
        case product
        case periodHeader
        
        var nibName: String {
            switch self {
            case .bildingInfo:
                return "STStorageBildingInfoCell"
            case .product:
                return "STStorageProductCell"
            case .periodHeader:
                return "STStoragePeriodHeaderView"
            }
        }
        
        var identifier: String {
            switch self {
            case .bildingInfo:
                return "bildingInfoCell"
            case .product:
                return "productCell"
            case .periodHeader:
                return "periodHeaderView"
            }
        }
        
        var kinde: Kinde {
            switch self {
            case .periodHeader:
                return .herader
            case .bildingInfo:
                return .cell
            case .product:
                return .cell
            }
        }
                
    }
        
}


extension STStorageVC {
    
    func generateSections(products: [STStore.Product], billingInfo: STBillingInfo) -> [Section] {
        let billingInfoSection = self.generateBillingInfoSection(billingInfo: billingInfo)
        let productsSection = self.generateProductsSection(products: products, billingInfo: billingInfo)
        return [billingInfoSection, productsSection]
    }
    
    func generateBillingInfoSection(billingInfo: STBillingInfo) -> Section {
        let usedSpace = billingInfo.spaceUsed
        let allSpace = billingInfo.spaceQuota
        let progress: Float = allSpace != 0 ? Float(usedSpace) / Float(allSpace) : 0
        let percent: Int = Int(progress * 100)
        let allSpaceGB = STBytesUnits(mb: Int64(allSpace))
        let used = String(format: "storage_space_used_info".localized, "\(usedSpace)", allSpaceGB.getReadableUnit(format: ".0f").uppercased(), "\(percent)")
        let model = STStorageBildingInfoCell.Model(title: "current_storage".localized, used: used, usedProgress: progress)
        let item = Item(item: model, reuseIdentifier: .bildingInfo)
        return Section(type: .bildingInfo, herader: nil, items: [item])
    }
    
    func item(for product: STStore.Product, selectedProductID: String?, productGroup: ProductGroup? = nil) -> Item {
        let productGroup = productGroup ?? ProductGroup.productGroup(for: product.productIdentifier)
        let isSelected = product.productIdentifier == selectedProductID
        let price = product.localizedPrice
        let quantity = productGroup?.product.localized ?? product.localizedTitle
        let period = product.period?.periodUnit.localized
        let identifier = product.productIdentifier + "_" + "\(isSelected)"
        let model = STStorageProductCell.Model(identifier: identifier, quantity: quantity, price: price, period: period, prodictID: product.productIdentifier, isSelected: isSelected)
        return Item(item: model, reuseIdentifier: .product)
    }
    
    func generateProductsHeader() -> Item {
        var model: IStorageItemModel!
        switch self.period {
        case .monthly:
            model = STStoragePeriodHeaderView.Model(description: "billed_monthly".localized, period: "yearly".localized, swich: false, info: "yearly_plan_save".localized)
        case .yearly:
            model = STStoragePeriodHeaderView.Model(description: "billed_yearly".localized, period: nil, swich: true, info: nil)
        }
        return Item(item: model, reuseIdentifier: .periodHeader)
    }
    
    func generateProductsSection(products: [STStore.Product], billingInfo: STBillingInfo) -> Section {
        var items = [Item]()
        let selectedProductID = self.selectedProductID ?? billingInfo.plan.identifier
        for product in products {
            let productGroup = ProductGroup.productGroup(for: product.productIdentifier)
            guard productGroup?.period == self.period else {
                continue
            }
            let item = self.item(for: product, selectedProductID: selectedProductID, productGroup: productGroup)
            items.append(item)
        }
        let header = self.generateProductsHeader()
        return Section(type: .product, herader: header, items: items)
        
    }
    
}
