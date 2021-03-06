//
//  STGalleryVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import UIKit

class STGalleryVC: UIViewController {
    
    @IBOutlet weak private var collectionView: UICollectionView!
    private var viewModel = STGalleryVM()
    private var dataSourceReference: UICollectionViewDiffableDataSourceReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureCollectionView()
        self.viewModel.reloadData()
    }
    
    private func configureCollectionView() {
        self.collectionView.registrCell(nibName: "STGalleryCollectionViewCell", identifier: "STGalleryCollectionViewCellID")
        self.collectionView.registerHeader(nibName: "STGaleryHeaderView", identifier: "STGaleryHeaderViewID")
        self.configureLayout()
        self.createDataBaseDataSounrs()
        self.createDataSourceReference()
    }

    //MARK: - DataSource
    
    private func createDataBaseDataSounrs() {
        self.viewModel.dataBaseDataSource.delegate = self
    }
    
    //MARK: - Layout
        
    @discardableResult
    private func configureLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            return self?.layoutSection(sectionIndex: sectionIndex, layoutEnvironment: layoutEnvironment)
        }
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
        group.contentInsets = NSDirectionalEdgeInsets(top: inset / 2, leading: inset, bottom: inset / 2, trailing: inset)
        group.interItemSpacing = .fixed(inset)
        let section = NSCollectionLayoutSection(group: group)
        
        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),  heightDimension: .estimated(55))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        sectionHeader.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 9, bottom: 7, trailing: 9)
        section.boundarySupplementaryItems = [sectionHeader]
        
        return section
    }
        
    private func generateCollectionLayoutItem() -> NSCollectionLayoutItem {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1))
        let resutl = NSCollectionLayoutItem(layoutSize: itemSize)
        return resutl
    }
    
    //MARK: - DataSourceReference
    
    private func createDataSourceReference()  {
        
        self.dataSourceReference = UICollectionViewDiffableDataSourceReference(collectionView: self.collectionView, cellProvider: { [weak self] (collectionView, indexPath, data) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "STGalleryCollectionViewCellID", for: indexPath)
            
            let obj = self?.viewModel.object(at: indexPath)
            
            return cell
        })
        
        self.dataSourceReference.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "STGaleryHeaderViewID", for: indexPath)
            let sectionName = self?.viewModel.sectionTitle(at: indexPath.section)
            (header as? STGaleryHeaderView)?.configure(title: sectionName)
            return header
        }
        
    }
    
}

extension STGalleryVC: IProviderDelegate {
    
    func dataSource(_ dataSource: IProviderDataSource, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        self.dataSourceReference.applySnapshot(snapshot, animatingDifferences: true)
    }
    
}
