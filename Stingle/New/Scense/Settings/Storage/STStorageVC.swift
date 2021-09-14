//
//  STStorageVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit 

class STStorageVC: UIViewController {
    
    private let viewModel = STStorageVM()
    
    @IBOutlet weak private var errorView: STView!
    @IBOutlet weak private var collectionView: UICollectionView!
    @IBOutlet weak private var errorMassageLabel: UILabel!
    @IBOutlet weak private var tryAgainButton: STButton!
    
    private(set) var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureLocalized()
        self.configureLayout()
        self.registerCollectionDataSource()
        self.reloadData(forceGet: false)
        self.viewModel.delegate = self
    }
    
    //MARK: - Private methods
    
    private func configureLayout() {
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int,
        layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            guard let weakSelf = self else {
                return nil
            }
            return weakSelf.collectionLayoutSection(for: sectionIndex, layoutEnvironment: layoutEnvironment)
        }
        self.collectionView.collectionViewLayout = layout
    }
    
    private func collectionLayoutSection(for sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
                
        let inset: CGFloat = 16
        let lineCount = sectionIndex == .zero ? 1 : layoutEnvironment.traitCollection.isHorizontalIpad() ? 2 : 1
        
        let item = self.generateCollectionLayoutItem()
        
        let itemSizeHeight: CGFloat =  sectionIndex == .zero ? 106 : 207
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemSizeHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: lineCount)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        group.interItemSpacing = .fixed(inset)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
        section.interGroupSpacing = inset
        section.removeContentInsetsReference(safeAreaInsets: self.collectionView.window?.safeAreaInsets)
        return section
    }
    
    private func generateCollectionLayoutItem() -> NSCollectionLayoutItem {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1))
        let resutl = NSCollectionLayoutItem(layoutSize: itemSize)
        resutl.contentInsets = .zero
        return resutl
    }
    
    private func registerCollectionDataSource() {
        
        CellReuseIdentifier.allCases.forEach { reuseIdentifier in
            self.collectionView.registrCell(nibName: reuseIdentifier.nibName, identifier: reuseIdentifier.rawValue)
        }
        
        self.dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: self.collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.reuseIdentifier.rawValue, for: indexPath)
            (cell as? IStorageCell)?.confugure(model: item.item)
            return cell
        }
        self.collectionView.dataSource = self.dataSource
    }
    
    private func applySnapshot(sectiosns: [Section], animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        sectiosns.forEach { section in
            snapshot.appendSections([section])
            snapshot.appendItems(section.items, toSection: section)
        }
        self.dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    private func configureLocalized() {
        self.navigationItem.title = "menu_storage".localized
        self.errorMassageLabel.text = "reconnect_server_try_again_message".localized
        self.tryAgainButton.setTitle("try_again".localized, for: .normal)
    }
    
    private func reloadData(forceGet: Bool) {
        let view: UIView = self.navigationController?.view ?? self.view
        STLoadingView.show(in: view)
        self.errorView.isHidden = true
        
        self.viewModel.getAllData(forceGet: forceGet) { [weak self] products, billingInfo in
            STLoadingView.hide(in: view)
            self?.reload(products: products, billingInfo: billingInfo)
            self?.collectionView.isHidden = false
        } failure: { [weak self] error in
            self?.collectionView.isHidden = true
            self?.errorView.isHidden = false
            self?.showError(error: error)
            STLoadingView.hide(in: view)
        }
    }
    
    private func reload(products: [STStore.Product], billingInfo: STBillingInfo) {
        let sections = self.generateSections(products: products, billingInfo: billingInfo)
        self.applySnapshot(sectiosns: sections)
    }
    
    //MARK: - Private user actions
    
    @IBAction private func didSelectTyyAgainButton(_ sender: Any) {
        self.reloadData(forceGet: true)
    }
    
    @IBAction private func didSelectMenuButton(_ sender: Any) {
        if self.splitMenuViewController?.isMasterViewOpened ?? false {
            self.splitMenuViewController?.hide(master: true)
        } else {
            self.splitMenuViewController?.show(master: true)
        }
    }
    
}

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
    
    func item(for product: STStore.Product, isCurrent: Bool) -> Item {
        let pearPrice = product.localizedPricePeriod
        let type: String? = isCurrent ? pearPrice : nil
                    
        var description = product.localizedDescription
        
        if let pearPrice = pearPrice {
            description = description + "\n" + pearPrice
        }
        
        let descriptionAtr = NSMutableAttributedString(string: description)
        
        if let pearPrice = pearPrice {
            descriptionAtr.setColor(color: .appPrimary, forText: pearPrice)
        }
        let model = STStorageProductCell.Model(identifier: product.productIdentifier, quantity: product.localizedTitle, type: type, byText: pearPrice, description: descriptionAtr, isCurrent: isCurrent)
        return Item(item: model, reuseIdentifier: .product)
    }
    
    func defaultProductItem() -> Item {
        let model = STStorageProductCell.Model(identifier: "defaultProduct", quantity: "1.0 GB", type: "free".localized, byText: "current_plan".localized, description: nil, isCurrent: true)
        return Item(item: model, reuseIdentifier: .product)
    }
    
    func generateProductsSection(products: [STStore.Product], billingInfo: STBillingInfo) -> Section {
        var items = [Item]()
        if billingInfo.plan == .free {
            let `default` = self.defaultProductItem()
            items.append(`default`)
            products.forEach { product in
                let item = self.item(for: product, isCurrent: false)
                items.append(item)
            }
        } else {
            products.forEach { product in
                let item = self.item(for: product, isCurrent: false)
                items.append(item)
            }
        }
        return Section(type: .product, items: items)
        
    }
    
}

extension STStorageVC: STStorageVMDelegate {
    
    func storageVM(didUpdateBildingInfo storageVM: STStorageVM) {
        self.reloadData(forceGet: true)
    }
    
}
