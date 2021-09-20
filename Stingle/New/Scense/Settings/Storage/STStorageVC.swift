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
        
        var contentInset = self.collectionView.contentInset
        contentInset.bottom = 20
        self.collectionView.contentInset = contentInset
        
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
        let lineCount = 1
        let item = self.generateCollectionLayoutItem(sectionIndex: sectionIndex)
        
        let itemSizeHeight: CGFloat =  sectionIndex == .zero ? 106 : 207
        
        let grouplWidth: NSCollectionLayoutDimension = .fractionalWidth(1)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: grouplWidth, heightDimension: .estimated(itemSizeHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: lineCount)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        group.interItemSpacing = .fixed(inset)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .zero
        section.interGroupSpacing = inset
        section.removeContentInsetsReference(safeAreaInsets: self.collectionView.window?.safeAreaInsets)
        return section
    }
    
    private func generateCollectionLayoutItem(sectionIndex: Int) -> NSCollectionLayoutItem {
        let itemSizeHeight: CGFloat =  sectionIndex == .zero ? 106 : 207
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(itemSizeHeight))
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
            let storageCell = (cell as? IStorageCell)
            storageCell?.delegate = self
            storageCell?.confugure(model: item.item)
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

extension STStorageVC: STStorageCellDelegate {
    
    func storageCell(didSelectBuy cell: STStorageProductCell, model: STStorageProductCell.Model.Button) {
        
        let view: UIView = self.navigationController?.view ?? self.view
        STLoadingView.show(in: view)
        
        self.viewModel.buy(product: model.identifier) { [weak self] error in
            STLoadingView.hide(in: view)
            if let error = error {
                self?.showError(error: error)
            }
        }
        
    }
    
}

extension STStorageVC: STStorageVMDelegate {
    
    func storageVM(didUpdateBildingInfo storageVM: STStorageVM) {
        self.reloadData(forceGet: true)
    }
    
}
