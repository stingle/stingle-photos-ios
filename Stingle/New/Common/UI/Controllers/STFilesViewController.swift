//
//  STFilesViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/12/21.
//

import UIKit

class STFilesViewController: UIViewController {
    
    @IBOutlet weak private(set) var collectionView: UICollectionView!
    private(set) var dataSourceReference: UICollectionViewDiffableDataSourceReference!
    private var lastOffSet: CGPoint?
    let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureLocalize()
        self.configureCollectionView()
        self.configureRefreshControl()
    }
    
    func configureLocalize() {
    }
    
    func configureCollectionView() {
        self.registrCollectionView()
        self.configureLayout()
        self.createDataSourceReference()
    }
    
    func registrCollectionView() {
        
    }
    
    func configureRefreshControl() {
        self.refreshControl.addTarget(self, action: #selector(self.refreshControl(didRefresh:)), for: .valueChanged)
        self.collectionView.addSubview(self.refreshControl)
    }
    
    @objc func refreshControl(didRefresh refreshControl: UIRefreshControl) {
        
    }
    
    @discardableResult
    func createDataSourceReference() -> UICollectionViewDiffableDataSourceReference  {
        self.dataSourceReference = UICollectionViewDiffableDataSourceReference(collectionView: self.collectionView, cellProvider: { [weak self] (collectionView, indexPath, data) -> UICollectionViewCell? in
            let cell = self?.cellFor(collectionView: collectionView, indexPath: indexPath, data: data)
            return cell
        })
        
        self.dataSourceReference.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            return self?.headerFor(collectionView: collectionView, indexPath: indexPath, kind: kind)
        }
        return self.dataSourceReference
    }
    
    func cellFor(collectionView: UICollectionView, indexPath: IndexPath, data: Any) -> UICollectionViewCell? {
        return nil
    }
    
    func headerFor(collectionView: UICollectionView, indexPath: IndexPath, kind: String) -> UICollectionReusableView? {
        return nil
    }
            
    @discardableResult
    func configureLayout(setLayout: Bool = true) -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            return self?.layoutSection(sectionIndex: sectionIndex, layoutEnvironment: layoutEnvironment)
        }, configuration: configuration)
        if setLayout {
            self.collectionView.collectionViewLayout = layout
        }
        return layout
    }
    
    func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        return nil
    }
    
    func generateCollectionLayoutItem() -> NSCollectionLayoutItem {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1))
        let resutl = NSCollectionLayoutItem(layoutSize: itemSize)
        resutl.contentInsets = .zero
        return resutl
    }
    
    func applySnapshot(_ snapshot: NSDiffableDataSourceSnapshotReference, animatingDifferences: Bool)  {
        self.dataSourceReference.applySnapshot(snapshot, animatingDifferences: animatingDifferences)
    }
    
    //MARK: private
    
    private func updateCollectionSplitAnimation(progress: CGFloat, isFrameUpdate: Bool) {
        guard let split = self.splitMenuViewController, let lastOffSet = self.lastOffSet else {
            return
        }
        let newWidth = split.detailViewWidth(progress: progress)
        let oldWidth = split.startDetailViewWidth()
        var offSet = lastOffSet
        offSet.y = offSet.y * newWidth / oldWidth
        var frame = self.collectionView.frame
        frame.size.width = newWidth
        frame.origin = .zero
        if isFrameUpdate {
            self.collectionView.frame = frame
        }
        let bottomOffset = self.collectionView.contentSize.height - self.collectionView.bounds.height + self.collectionView.contentInset.bottom
        
        offSet.y = min(bottomOffset, offSet.y)

        self.collectionView.contentOffset = offSet
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    

}
