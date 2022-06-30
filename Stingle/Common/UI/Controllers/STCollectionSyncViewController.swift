//
//  STFilesViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/12/21.
//

import UIKit

class STCollectionSyncViewController<ViewModel: ICollectionDataSourceViewModel>: UIViewController, STCollectionViewDataSourceDelegate {
    
    private(set) var dataSource: STCollectionViewDataSource<ViewModel>!
    let refreshControl = UIRefreshControl()
    
    @IBOutlet weak private(set) var collectionView: UICollectionView!
    @IBOutlet weak var emptyDataView: UIView?
    @IBOutlet weak var emptyDataTitleLabel: UILabel?
    @IBOutlet weak var emptyDataSubTitleLabel: UILabel?
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureRefreshControl()
        self.dataSource = self.createDataSource()
        self.dataSource.delegate = self
        self.dataSource.reloadData()
        self.updateEmptyView()
        self.configureLocalize()
        STApplication.shared.syncManager.addListener(self)
    }
    
    func configureLocalize() {}
    
    func configureRefreshControl() {
        guard self.shouldAddRefreshControl() else {
            return
        }
        self.refreshControl.addTarget(self, action: #selector(self.refreshControl(didRefresh:)), for: .valueChanged)
        self.collectionView.addSubview(self.refreshControl)
    }
    
    func shouldAddRefreshControl() -> Bool {
        return true
    }
    
    func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        return nil
    }
    
    func createDataSource() -> STCollectionViewDataSource<ViewModel> {
        fatalError("method not implemented")
    }
    
    func didStartSync() {
        self.refreshControl.beginRefreshing()
        self.updateEmptyView()
    }
    
    func didEndSync() {
        self.refreshControl.endRefreshing()
        self.updateEmptyView()
    }
    
    func refreshControlDidRefresh() {}
    
    func updateEmptyView() {
        if self.isSyncing {
            self.updateEmptyViewSyncing()
        } else {
            self.updateEmptyViewWithOutSyncing()
        }
    }
    
    func updateEmptyViewSyncing() {
        if self.dataSource.isEmptyData {
            self.activityIndicatorView?.startAnimating()
        }
        self.emptyDataView?.isHidden = true
    }
    
    func updateEmptyViewWithOutSyncing() {
        self.activityIndicatorView?.stopAnimating()
        self.emptyDataView?.isHidden = !self.dataSource.isEmptyData
    }
    
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
    
    //MARK: - STCollectionViewDataSourceDelegate
    
    func dataSource(layoutSection dataSource: IViewDataSource, sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        return self.layoutSection(sectionIndex: sectionIndex, layoutEnvironment: layoutEnvironment)
    }
    
    func dataSource(didStartSync dataSource: IViewDataSource) {}
    func dataSource(didEndSync dataSource: IViewDataSource) {}
    func dataSource(didConfigureCell dataSource: IViewDataSource, cell: UICollectionViewCell) {}
    func dataSource(didApplySnapshot dataSource: IViewDataSource) {}
    
    func dataSource(willApplySnapshot dataSource: IViewDataSource) {
        self.updateEmptyView()
    }
    
}

extension STCollectionSyncViewController: ISyncManagerObserver {
    
    var isSyncing: Bool {
        return STApplication.shared.syncManager.isSyncing
    }
    
    func syncManager(didStartSync syncManager: STSyncManager) {
        self.didStartSync()
    }
    
    func syncManager(didEndSync syncManager: STSyncManager, with error: IError?) {
        self.didEndSync()
    }
    
}
