//
//  STFilesViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/12/21.
//

import UIKit

class STFilesViewController<ViewModel: ICollectionDataSourceViewModel>: UIViewController {
    
    private(set) var dataSource: STCollectionViewDataSource<ViewModel>!
    let refreshControl = UIRefreshControl()
    
    @IBOutlet weak private(set) var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureLocalize()
        self.configureRefreshControl()
        self.dataSource = self.createDataSource()
        self.dataSource.delegate = self
        self.dataSource.reloadData()
    }
    
    func configureLocalize() {}
    
    func configureRefreshControl() {
        self.refreshControl.addTarget(self, action: #selector(self.refreshControl(didRefresh:)), for: .valueChanged)
        self.collectionView.addSubview(self.refreshControl)
    }
    
    func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        return nil
    }
    
    func createDataSource() -> STCollectionViewDataSource<ViewModel> {
        fatalError("method not implemented")
    }
    
    func didStartSync() {
        self.refreshControl.beginRefreshing()
    }
    
    func didEndSync() {
        self.refreshControl.endRefreshing()
    }
    
    func refreshControlDidRefresh() {}
    
    //MARK: - Urer Acction
    
    @IBAction private func didSelectMenuBarItem(_ sender: Any) {
        if self.splitMenuViewController?.isMasterViewOpened ?? false {
            self.splitMenuViewController?.hide(master: true)
        } else {
            self.splitMenuViewController?.show(master: true)
        }
    }
    
    @objc private func refreshControl(didRefresh refreshControl: UIRefreshControl) {
        self.refreshControlDidRefresh()
    }
    
}

extension STFilesViewController: STCollectionViewDataSourceDelegate {
    
    func dataSource(layoutSection dataSource: IViewDataSource, sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        return self.layoutSection(sectionIndex: sectionIndex, layoutEnvironment: layoutEnvironment)
    }
    
    func dataSource(didStartSync dataSource: IViewDataSource) {
        self.didStartSync()
    }
    
    func dataSource(didEndSync dataSource: IViewDataSource) {
        self.didEndSync()
    }
    
}
