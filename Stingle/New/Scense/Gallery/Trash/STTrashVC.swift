//
//  STTrashVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/6/21.
//

import UIKit

class STTrashVC: STFilesViewController {
    
    private let viewModel = STTrashVM()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.dataBaseDataSource.delegate = self
        self.viewModel.reloadData()
    }
    
    override func configureLocalize() {
        super.configureLocalize()
        self.navigationItem.title = "trash".localized
        self.navigationController?.tabBarItem.title = "trash".localized
    }
    
    override func registrCollectionView() {
        super.registrCollectionView()
        self.collectionView.registrCell(nibName: "STTrashCollectionViewCell", identifier: "STTrashCollectionViewCellID")
        self.collectionView.registerHeader(nibName: "STTrashHeaderView", identifier: "STTrashHeaderViewID")
    }
    
    @objc override func refreshControl(didRefresh refreshControl: UIRefreshControl) {
        self.viewModel.sync()
    }
    
    override func cellFor(collectionView: UICollectionView, indexPath: IndexPath, data: Any) -> UICollectionViewCell? {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "STTrashCollectionViewCellID", for: indexPath)
        let item = self.viewModel.item(at: indexPath)
        (cell as? STTrashCollectionViewCell)?.configure(viewItem: item)
        return cell
    }
    
    override func headerFor(collectionView: UICollectionView, indexPath: IndexPath, kind: String) -> UICollectionReusableView? {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "STTrashHeaderViewID", for: indexPath)
        let sectionName = self.viewModel.sectionTitle(at: indexPath.section)
        (header as? STTrashHeaderView)?.configure(title: sectionName)
        return header
    }
    
    override func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let inset: CGFloat = 4
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 5 : 3
        let item = self.generateCollectionLayoutItem()
        let itemSizeWidth = (layoutEnvironment.container.contentSize.width - 2 * inset) / CGFloat(lineCount)
        let itemSizeHeight = itemSizeWidth
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemSizeHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: lineCount)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        group.interItemSpacing = .fixed(inset)
                
        let section = NSCollectionLayoutSection(group: group)
        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),  heightDimension: .absolute(38))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        sectionHeader.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 9, bottom: 0, trailing: 9)
        section.boundarySupplementaryItems = [sectionHeader]
        section.contentInsets = .zero
        section.interGroupSpacing = inset
        section.removeContentInsetsReference(safeAreaInsets: self.collectionView.window?.safeAreaInsets)
        return section
    }
    
    @IBAction private func didSelectMenuBarItem(_ sender: Any) {
        if self.splitMenuViewController?.isMasterViewOpened ?? false {
            self.splitMenuViewController?.hide(master: true)
        } else {
            self.splitMenuViewController?.show(master: true)
        }
    }
    

}

extension STTrashVC: IProviderDelegate {
    
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.viewModel.removeCache()
        self.applySnapshot(snapshot, animatingDifferences: true)
    }
    
    func didEndSync(dataSource: IProviderDataSource) {
        self.refreshControl.endRefreshing()
    }
    
    func didStartSync(dataSource: IProviderDataSource) {
        self.refreshControl.beginRefreshing()
    }
    
}
