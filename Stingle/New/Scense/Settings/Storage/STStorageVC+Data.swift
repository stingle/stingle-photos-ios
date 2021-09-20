//
//  STStorageVC+Data.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/20/21.
//

import Foundation

extension STStorageVC {
        
    struct Section: Hashable {

        enum SectionType: String {
            case bildingInfo = "bildingInfo"
            case product = "product"
        }
        
        let type: SectionType
        let items: [Item]
        
        static func == (lhs: STStorageVC.Section, rhs: STStorageVC.Section) -> Bool {
            return lhs.type == rhs.type
        }
        
        func hash(into hasher: inout Hasher) {
            return self.type.hash(into: &hasher)
        }
        
    }
    
    struct Item: Hashable {
        
        var item: IStorageCellModel
        var reuseIdentifier: CellReuseIdentifier

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.item.identifier)
        }

        static func == (lhs: Item, rhs: Item) -> Bool {
            return lhs.item.identifier == rhs.item.identifier
        }

    }
    
    enum CellReuseIdentifier: String, CaseIterable {
        case bildingInfo = "bildingInfoCell"
        case product = "productCell"
        
        var nibName: String {
            switch self {
            case .bildingInfo:
                return "STStorageBildingInfoCell"
            case .product:
                return "STStorageProductCell"
            }
        }
                
    }
    
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
        return Section(type: .bildingInfo, items: [item])
    }
    
    func item(forMounth mounth: STStore.Product, year: STStore.Product) -> Item {
        let mounthButton = STStorageProductCell.Model.Button(text: "current_plan".localized, isEnabled: false, identifier: mounth.productIdentifier)
        let pearMounthPrice = mounth.localizedPricePeriod ?? ""
        
        let pearYearPrice = year.localizedPricePeriod ?? ""
        let yearButton = STStorageProductCell.Model.Button(text: pearYearPrice, isEnabled: true, identifier: year.productIdentifier)
        let currencyCode = mounth.currencyCode ?? ""
        let saved = mounth.priceValue * 12 - year.priceValue
        let description = String(format: "yearly_plan_save".localized, currencyCode, saved)
        
        let identifier = mounth.productIdentifier + year.productIdentifier
        let model = STStorageProductCell.Model(identifier: identifier, quantity: mounth.localizedTitle, type: pearMounthPrice, buyButtonFirst: mounthButton, description: description, buyButtonSecondary: yearButton, isHighlighted: true)
        
        return Item(item: model, reuseIdentifier: .product)
    }
    
    func item(forYear mounth: STStore.Product, year: STStore.Product) -> Item {
        
        let pearYearPrice = year.localizedPricePeriod ?? ""
        let yearButton = STStorageProductCell.Model.Button(text: "current_plan".localized, isEnabled: false, identifier: year.productIdentifier)
        
        let pearMounthPrice = mounth.localizedPricePeriod ?? ""
        let mounthButton = STStorageProductCell.Model.Button(text: pearMounthPrice, isEnabled: true, identifier: mounth.productIdentifier)
        
        let identifier = mounth.productIdentifier + year.productIdentifier
        let model = STStorageProductCell.Model(identifier: identifier, quantity: year.localizedTitle, type: pearYearPrice, buyButtonFirst: yearButton, description: nil, buyButtonSecondary: mounthButton, isHighlighted: true)
        return Item(item: model, reuseIdentifier: .product)
    }
    
    
    func item(for mounth: STStore.Product, year: STStore.Product) -> Item {
        
        let pearMounthPrice = mounth.localizedPricePeriod ?? ""
        let mounthButton = STStorageProductCell.Model.Button(text: pearMounthPrice, isEnabled: true, identifier: mounth.productIdentifier)
        
        let pearYearPrice = year.localizedPricePeriod ?? ""
        let yearButton = STStorageProductCell.Model.Button(text: pearYearPrice, isEnabled: true, identifier: year.productIdentifier)
        let currencyCode = mounth.currencyCode ?? ""
        let saved = mounth.priceValue * 12 - year.priceValue
        let description = String(format: "yearly_plan_save".localized, currencyCode, saved)
        
        let identifier = mounth.productIdentifier + year.productIdentifier
        let model = STStorageProductCell.Model(identifier: identifier, quantity: mounth.localizedTitle, type: nil, buyButtonFirst: mounthButton, description: description, buyButtonSecondary: yearButton, isHighlighted: false)
        
        return Item(item: model, reuseIdentifier: .product)
    }
    
    func item(for mounth: STStore.Product, year: STStore.Product, billingInfo: STBillingInfo) -> Item {
        if billingInfo.plan.identifier == mounth.productIdentifier {
            return self.item(forMounth: mounth, year: year)
        } else if billingInfo.plan.identifier == year.productIdentifier {
            return self.item(forYear: mounth, year: year)
        }
        return self.item(for: mounth, year: year)
    }
    
    func item(for product: STStore.Product, billingInfo: STBillingInfo) -> Item {
        let isCurrent = product.productIdentifier == billingInfo.plan.identifier
        let pearPrice = product.localizedPricePeriod ?? ""
        let title = isCurrent ? "current_plan".localized : pearPrice
        let button = STStorageProductCell.Model.Button(text: title, isEnabled: !isCurrent, identifier: product.productIdentifier)
        let model = STStorageProductCell.Model(identifier: product.productIdentifier, quantity: product.localizedTitle, type: nil, buyButtonFirst: button, description: nil, buyButtonSecondary: nil, isHighlighted: isCurrent)
        return Item(item: model, reuseIdentifier: .product)
    }
    
    func freeProductItem() -> Item {
        let button = STStorageProductCell.Model.Button(text: "current_plan".localized, isEnabled: false, identifier: "defaultProduct")
        let model = STStorageProductCell.Model(identifier: "defaultProduct", quantity: "1.0 GB", type: "free".localized, buyButtonFirst: button, description: nil, buyButtonSecondary: nil, isHighlighted: true)
        return Item(item: model, reuseIdentifier: .product)
    }
    
    func generateProductsSection(products: [STStore.Product], billingInfo: STBillingInfo) -> Section {
        var items = [Item]()
        
        let allIdentifiers = STStorageVM.ProductGroup.allIdentifiers
        
        var productsGroup = [String: STStore.Product]()
        
        products.forEach { product in
            productsGroup[product.productIdentifier] = product
        }
        
        var selectedItem: Item?
        
        for identifiers in allIdentifiers {
            var item: Item?
            if let mount = productsGroup[identifiers.monthly], let year = productsGroup[identifiers.yearly] {
                item = self.item(for: mount, year: year, billingInfo: billingInfo)
            } else if let product = productsGroup[identifiers.monthly] {
                item = self.item(for: product, billingInfo: billingInfo)
            } else if let product = productsGroup[identifiers.yearly] {
                item = self.item(for: product, billingInfo: billingInfo)
            }
            guard let item = item else {
                continue
            }                        
            if identifiers.monthly == billingInfo.plan.identifier || identifiers.yearly == billingInfo.plan.identifier {
                selectedItem = item
            } else {
                items.append(item)
            }
            
        }
        
        if let selectedItem = selectedItem {
            items.insert(selectedItem, at: .zero)
        } else if billingInfo.plan == .free {
            let `default` = self.freeProductItem()
            items.insert(`default`, at: .zero)
        }

        return Section(type: .product, items: items)
        
    }
    
}
