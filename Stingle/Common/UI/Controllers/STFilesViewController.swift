//
//  STFilesViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/12/21.
//

import UIKit

class STFilesViewController<ViewModel: ICollectionDataSourceViewModel>: UIViewController, STCollectionViewDataSourceDelegate {
    
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

extension STFilesViewController: ISyncManagerObserver {
    
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

class STFilesSelectionViewController<ViewModel: ICollectionDataSourceViewModel>: STFilesViewController<ViewModel>, UICollectionViewDelegate {
    
    private(set) var isSelectionMode = false
    private(set) var selectionObjectsIdentifiers = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSelectionMode()
    }
    
    //MARK: - Public methods
    
    func setSelectionMode(isSelectionMode: Bool) {
        guard self.isSelectionMode != isSelectionMode else {
            return
        }
        self.isSelectionMode = isSelectionMode
        self.selectionObjectsIdentifiers.removeAll()
        if #available(iOS 14.0, *) {
            self.collectionView.isEditing = isSelectionMode
        }
        self.collectionView.reloadData()
    }
    
    func collectionView(didSelectItemAt indexPath: IndexPath) {
        //Implement chid classes
    }
    
    func collectionView(didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        //Implement chid classes
    }
    
    func collectionViewDidEndMultipleSelectionInteraction() {
        //Implement chid classes
    }
    
    func updatedSelect(for indexPath: IndexPath, isSlected: Bool) {
        guard let identifier = self.dataSource.object(at: indexPath)?.identifier else {
            return
        }
        if isSlected {
            self.selectionObjectsIdentifiers.insert(identifier)
        } else {
            self.selectionObjectsIdentifiers.remove(identifier)
        }
    }

    //MARK: - Private methods
    
    private func configureSelectionMode() {
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = false
        if #available(iOS 14.0, *) {
            self.collectionView.allowsMultipleSelectionDuringEditing = true
        }
    }
        
    //MARK: - UITableViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.isSelectionMode {
            self.updatedSelect(for: indexPath, isSlected: true)
        }
        self.collectionView(didSelectItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if self.isSelectionMode {
            self.updatedSelect(for: indexPath, isSlected: false)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        self.collectionView(didBeginMultipleSelectionInteractionAt: indexPath)
    }
    
    func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        self.collectionViewDidEndMultipleSelectionInteraction()
    }

}
