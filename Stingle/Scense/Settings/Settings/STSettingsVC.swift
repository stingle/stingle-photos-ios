//
//  STSettingsVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/6/21.
//

import UIKit

class STSettingsVC: UIViewController {

    @IBOutlet weak private var collectionView: UICollectionView!
    
    typealias DataSource = UICollectionViewDiffableDataSource<Int, CellItem>
    
    private var items = [CellItem]()
    private var dataSource: DataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureItems()
        self.configureLayout()
        self.registerCollectionDataSource()
        self.applySnapshot()
    }
    
    //MARK: - Private methods
    
    private func configureItems() {
        let account = CellItem(image: UIImage(named: "ic_settings_account")!, title: "account".localized, itemType: .account)
        let security = CellItem(image: UIImage(named: "ic_settings_security")!, title: "security".localized, itemType: .security)
        let backup = CellItem(image: UIImage(named: "ic_settings_backup")!, title: "backup".localized, itemType: .backup)
//        let `import` = CellItem(image: UIImage(named: "ic_settings_import")!, title: "import".localized, itemType: .import)
        let appearance = CellItem(image: UIImage(named: "ic_settings_appearance")!, title: "appearance".localized, itemType: .appearance)
        let advanced = CellItem(image: UIImage(named: "ic_settings_advanced")!, title: "advanced".localized, itemType: .advanced)
        self.items = [account, security, backup, appearance, advanced]
    }
    
    //MARK: - Collection view Layout
    
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
        
        let inset: CGFloat = 4
        let lineCount = layoutEnvironment.traitCollection.isHorizontalIpad() ? 2 : 1
        
        let item = self.generateCollectionLayoutItem()
        
        let itemSizeHeight: CGFloat = 60
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemSizeHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: lineCount)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        group.interItemSpacing = .fixed(inset)
                
        let section = NSCollectionLayoutSection(group: group)
       
        section.contentInsets = .zero
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
    
    //MARK: - Collection view DataSource
    
    private func registerCollectionDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<Int, CellItem>(collectionView: self.collectionView) { (collectionView, indexPath, itemType) -> UICollectionViewCell? in
            let item = itemType
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellID", for: indexPath)
            (cell as? STSettingsCollectionViewCell)?.configure(viewModel: item)
            return cell
        }
        self.collectionView.dataSource = self.dataSource
    }
    
    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CellItem>()
        let sectionType: Int = .zero
        snapshot.appendSections([sectionType])
        snapshot.appendItems(self.items, toSection: sectionType)
        self.dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    //MARK: - User action
    
    @IBAction private func didSelectMenuBarItem(_ sender: Any) {
        if self.splitMenuViewController?.isMasterViewOpened ?? false {
            self.splitMenuViewController?.hide(master: true)
        } else {
            self.splitMenuViewController?.show(master: true)
        }
    }
    
}

extension STSettingsVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        self.performSegue(withIdentifier: item.itemType.stID, sender: nil)
    }
    
}

extension STSettingsVC {
    
    struct CellItem: Hashable {
        let image: UIImage
        let title: String
        let itemType: ItemType
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.itemType)
            hasher.combine(self.title)
        }
        
        static func == (lhs: CellItem, rhs: CellItem) -> Bool {
            return lhs.itemType == rhs.itemType && lhs.title == rhs.title
        }
    }
    
    enum ItemType {
        case account
        case security
        case backup
        case `import`
        case appearance
        case advanced
        
        var stID: String {
            switch self {
            case .account:
                return "STAccountVCID"
            case .security:
                return "STSecurityVCID"
            case .backup:
                return "STBackupVCID"
            case .import:
                return "STImportVCID"
            case .appearance:
                return "STAppearanceVCID"
            case .advanced:
                return "STAdvancedVCID"
            }
        }
        
    }
    
}
