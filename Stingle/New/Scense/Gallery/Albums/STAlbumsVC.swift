//
//  STAlbumsVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import UIKit

class STAlbumsVC: UIViewController {
    
    @IBOutlet weak private(set) var collectionView: UICollectionView!
    
    private let viewModel = STAlbumsVM()
    private var dataSource: STAlbumsDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureLocalize()
        self.dataSource = STAlbumsDataSource(collectionView: self.collectionView)
        self.dataSource.delegate = self
        self.dataSource.reloadData()
    }
    
    func configureLocalize() {
        self.navigationItem.title = "albums".localized
        self.navigationController?.tabBarItem.title = "albums".localized
    }

    @objc func refreshControl(didRefresh refreshControl: UIRefreshControl) {
        self.viewModel.sync()
    }
    
    @IBAction private func didSelectMenuBarItem(_ sender: Any) {
        if self.splitMenuViewController?.isMasterViewOpened ?? false {
            self.splitMenuViewController?.hide(master: true)
        } else {
            self.splitMenuViewController?.show(master: true)
        }
    }
    
}

extension STAlbumsVC: STCollectionViewDataSourceDelegate {
    
    func dataSource(layoutSection dataSource: IViewDataSource, sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let inset: CGFloat = 4
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 3 : 2
        let item = self.dataSource.generateCollectionLayoutItem()
        let itemSizeWidth = (layoutEnvironment.container.contentSize.width - 2 * inset) / CGFloat(lineCount)
        let itemSizeHeight = itemSizeWidth
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
    
    
}


