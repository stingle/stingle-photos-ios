//
//  STGalleryVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import UIKit
import Kingfisher

class STGalleryVC: UIViewController {
    
    @IBOutlet weak private var collectionView: UICollectionView!
   
    private var viewModel = STGalleryVM()
    private weak var syncHeaderView: STHomeSyncCollectionReusableView?
    private var dataSourceReference: UICollectionViewDiffableDataSourceReference!
    private let globalHeaderViewKind = "globalHeaderViewKind"
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureLocalize()
        self.configureCollectionView()
        self.viewModel.reloadData()
        self.configureRefreshControl()
    }
    
    private func configureCollectionView() {
        self.collectionView.registrCell(nibName: "STGalleryCollectionViewCell", identifier: "STGalleryCollectionViewCellID")
        self.collectionView.registerHeader(nibName: "STGaleryHeaderView", identifier: "STGaleryHeaderViewID")
        self.collectionView.registerHeader(nibName: "STHomeSyncCollectionReusableView", kind: self.globalHeaderViewKind)
        self.configureLayout()
        self.createDataBaseDataSounrs()
        self.createDataSourceReference()
    }
    
    private func configureLocalize() {
        self.navigationItem.title = "gallery".localized
        self.navigationController?.tabBarItem.title = "gallery".localized
    }
    
    private func configureRefreshControl() {
        self.refreshControl.addTarget(self, action: #selector(self.refreshControl(didRefresh:)), for: .valueChanged)
        self.collectionView.addSubview(self.refreshControl)
    }
    
    //MARK: - User action
    
    @objc func refreshControl(didRefresh refreshControl: UIRefreshControl) {
        self.syncHeaderView?.configure(state: .refreshing)
        self.viewModel.sync { [weak self] (_) in
            self?.refreshControl.endRefreshing()
        }
    }

    //MARK: - DataSource
    
    private func createDataBaseDataSounrs() {
        self.viewModel.dataBaseDataSource.delegate = self
    }
    
    //MARK: - Layout
        
    @discardableResult
    private func configureLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        let globalHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
        let globalHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: globalHeaderSize, elementKind: self.globalHeaderViewKind, alignment: .top)
        globalHeader.zIndex = Int.max
        globalHeader.pinToVisibleBounds = true
        configuration.boundarySupplementaryItems = [globalHeader]
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            return self?.layoutSection(sectionIndex: sectionIndex, layoutEnvironment: layoutEnvironment)
        }, configuration: configuration)
        layout.register(UINib(nibName: "STHomeSyncCollectionReusableView", bundle: .main), forDecorationViewOfKind: self.globalHeaderViewKind)
        layout.configuration.boundarySupplementaryItems = [globalHeader]
        self.collectionView.collectionViewLayout = layout
        return layout
    }
    
    private func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
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
        
        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),  heightDimension: .estimated(55))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                
        sectionHeader.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 9, bottom: 0, trailing: 9)
        
        section.boundarySupplementaryItems = [sectionHeader]
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
    
    //MARK: - DataSourceReference
    
    private func createDataSourceReference()  {
        self.dataSourceReference = UICollectionViewDiffableDataSourceReference(collectionView: self.collectionView, cellProvider: { [weak self] (collectionView, indexPath, data) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "STGalleryCollectionViewCellID", for: indexPath)
            let item = self?.viewModel.item(at: indexPath) 
            (cell as? STGalleryCollectionViewCell)?.configure(viewItem: item)
            return cell
        })
        
        self.dataSourceReference.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            if kind == self?.globalHeaderViewKind {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath)
                self?.syncHeaderView = (header as? STHomeSyncCollectionReusableView)
                return header
            } else {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "STGaleryHeaderViewID", for: indexPath)
                let sectionName = self?.viewModel.sectionTitle(at: indexPath.section)
                (header as? STGaleryHeaderView)?.configure(title: sectionName)
                return header
            }
        }
    }
    
}

extension STGalleryVC: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let alpha: CGFloat = scrollView.contentOffset.y > 200 ? 0 : 1
        self.syncHeaderView?.update(alpha: alpha)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? STGalleryCollectionViewCell
        let item = self.viewModel.item(at: indexPath)
        cell?.configure(viewItem: item)
    }
    
}

extension STGalleryVC: IProviderDelegate {
    
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.viewModel.removeCache()
        self.dataSourceReference.applySnapshot(snapshot, animatingDifferences: true)
    }
    
    func didEndSync(dataSource: IProviderDataSource) {
        self.syncHeaderView?.configure(state: .syncComplete)
    }
    
    func didStartSync(dataSource: IProviderDataSource) {
        self.syncHeaderView?.configure(state: .refreshing)
    }
    
}
