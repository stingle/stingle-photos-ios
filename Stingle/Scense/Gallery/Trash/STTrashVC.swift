//
//  STTrashVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/6/21.
//

import UIKit

//MARK: - STTrashVC VM

extension STTrashVC {
    
    struct ViewModel: ICollectionDataSourceViewModel {
                              
        typealias Header = STTrashHeaderView
        typealias Cell = STTrashCollectionViewCell
        typealias CDModel = STCDTrashFile
        
        var isSelectedMode = false
        
        func cellModel(for indexPath: IndexPath, data: STLibrary.TrashFile) -> STTrashVC.CellModel {
            let image = STImageView.Image(file: data, isThumb: true)
            var videoDurationStr: String? = nil
            if let duration = data.decryptsHeaders.file?.videoDuration, duration > 0 {
                videoDurationStr = TimeInterval(duration).timeFormat()
            }
            return CellModel(image: image,
                             name: data.file,
                             videoDuration: videoDurationStr,
                             isRemote: data.isRemote,
                             selectedMode: self.isSelectedMode)
        }
        
        func headerModel(for indexPath: IndexPath, section: String) -> STTrashVC.HeaderModel {
            return STTrashVC.HeaderModel(text: section)
        }
    }
    
    struct CellModel: IViewDataSourceCellModel {
        let identifier: Identifier = .cell
        let image: STImageView.Image?
        let name: String?
        let videoDuration: String?
        let isRemote: Bool
        let selectedMode: Bool
    }
    
    struct HeaderModel: IViewDataSourceHeaderModel {
        let identifier: Identifier = .header
        let text: String?
    }
    
    enum Identifier: CaseIterable, IViewDataSourceItemIdentifier {
        case cell
        case header
        
        var nibName: String {
            switch self {
            case .cell:
                return "STTrashCollectionViewCell"
            case .header:
                return "STTrashHeaderView"
            }
        }
        
        var identifier: String {
            switch self {
            case .cell:
                return "STTrashCollectionViewCellID"
            case .header:
                return "STTrashHeaderViewID"
            }
        }
    }
        
}


class STTrashVC: STFilesSelectionViewController<STTrashVC.ViewModel> {
    
    @IBOutlet weak private var selectButtonItem: UIBarButtonItem!
    
    private var selectedItem: STLibrary.TrashFile?
    private let viewModel = STTrashVM()
    
    lazy private var accessoryView: STFilesActionTabBarAccessoryView = {
        let resilt = STFilesActionTabBarAccessoryView.loadNib()
        return resilt
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.accessoryView.dataSource = self
        self.updateTabBarAccessoryView()
        self.updateSelectedItesmCount()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (self.tabBarController?.tabBar as? STTabBar)?.accessoryView = self.accessoryView
    }
    
    override func dataSource(didApplySnapshot dataSource: IViewDataSource) {
        super.dataSource(didApplySnapshot: dataSource)
        self.updateTabBarAccessoryView()
        self.updateSelectedItesmCount()
    }

    override func configureLocalize() {
        super.configureLocalize()
        self.navigationItem.title = "trash".localized
        self.navigationController?.tabBarItem.title = nil
        self.emptyDataTitleLabel?.text = "empy_trash_title".localized
        self.emptyDataSubTitleLabel?.text = "empy_trash_message".localized
        self.selectButtonItem.title = "select".localized
    }
    
    override func createDataSource() -> STCollectionViewDataSource<ViewModel> {
        let dbDataSource = self.viewModel.createDBDataSource()
        let viewModel = ViewModel()
        return STCollectionViewDataSource<ViewModel>(dbDataSource: dbDataSource,
                                                     collectionView: self.collectionView,
                                                     viewModel: viewModel)
    }
    
    override func refreshControlDidRefresh() {
        self.viewModel.sync()
    }
    
    override func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let inset: CGFloat = 4
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 5 : layoutEnvironment.container.contentSize.width > layoutEnvironment.container.contentSize.height ? 5 : 3
        let item = self.dataSource.generateCollectionLayoutItem()
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
    
    override func setSelectionMode(isSelectionMode: Bool) {
        guard self.isSelectionMode != isSelectionMode else {
            return
        }
        self.dataSource.viewModel.isSelectedMode = isSelectionMode
        super.setSelectionMode(isSelectionMode: isSelectionMode)
        self.updateTabBarAccessoryView()
        self.selectButtonItem.title = self.dataSource.viewModel.isSelectedMode ? "cancel".localized : "select".localized
        self.updateSelectedItesmCount()
    }
    
    override func updatedSelect(for indexPath: IndexPath, isSlected: Bool) {
        super.updatedSelect(for: indexPath, isSlected: isSlected)
        self.updateSelectedItesmCount()
    }
    
    override func collectionView(didSelectItemAt indexPath: IndexPath) {
        guard !self.isSelectionMode, let file = self.dataSource.object(at: indexPath) else {
            return
        }
        self.selectedItem = file
        let sorting = self.viewModel.getSorting()
        let vc = STFileViewerVC.create(trash: file, sortDescriptorsKeys: sorting)
        self.show(vc, sender: nil)
    }
    
    //MARK: - UserAction
    
    @IBAction private func didSelectSelecedButtonItem(_ sender: UIBarButtonItem) {
        self.setSelectionMode(isSelectionMode: !self.isSelectionMode)
    }
    
    //MARK: - Private methods
        
    private func updateTabBarAccessoryView() {
        self.accessoryView.reloadData()
    }
    
    private func updateSelectedItesmCount() {
        let count = self.selectionObjectsIdentifiers.count
        let title = self.isSelectionMode ? count == 0 ? "select_items".localized : String(format: "selected_items_count".localized, "\(count)") : nil
        self.accessoryView.title = title
        let isEnabled = self.isSelectionMode ? count != .zero : !self.dataSource.isEmptyData
        self.accessoryView.setEnabled(isEnabled: isEnabled)
    }
    
    private func didSelectedTrash() {
        guard !self.selectionObjectsIdentifiers.isEmpty else {
            return
        }
        
        let fileNames = [String](self.selectionObjectsIdentifiers)
        let files = self.viewModel.getFiles(fileNames: fileNames)
        let loadingView: UIView = self.tabBarController?.view ?? self.view
                
        let title = "delete_files_alert_title".localized
        let message = String(format: "delete_files_alert_message".localized, "\(files.count)")
        
        self.showOkCancelAlert(title: title, message: message, handler:  { [weak self] _ in
            STLoadingView.show(in: loadingView)
            self?.viewModel.delete(files: files, completion: { error in
                STLoadingView.hide(in: loadingView)
                if let error = error {
                    self?.showError(error: error)
                } else {
                    self?.setSelectionMode(isSelectionMode: false)
                }
            })
        })
        
    }
    
    private func didSelectedRecover() {
        guard !selectionObjectsIdentifiers.isEmpty else {
            return
        }
        
        let fileNames = [String](self.selectionObjectsIdentifiers)
        let files = self.viewModel.getFiles(fileNames: fileNames)
        let loadingView: UIView = self.tabBarController?.view ?? self.view

        STLoadingView.show(in: loadingView)
        self.viewModel.recover(files: files, completion: { [weak self] error in
            STLoadingView.hide(in: loadingView)
            if let error = error {
                self?.showError(error: error)
            } else {
                self?.setSelectionMode(isSelectionMode: false)
            }
        })
    }
    
    private func didSelectedDeleteAll() {
        
        let loadingView: UIView = self.tabBarController?.view ?? self.view
        let title = "empty_trash".localized
        let message = "delete_all_files_alert_message".localized
       
        self.showOkCancelAlert(title: title, message: message, handler:  { [weak self] _ in
            STLoadingView.show(in: loadingView)
            self?.viewModel.deleteAll(completion: { error in
                STLoadingView.hide(in: loadingView)
                if let error = error {
                    self?.showError(error: error)
                } else {
                    self?.setSelectionMode(isSelectionMode: false)
                }
            })
        })
    }
    
    private func didSelectedRecoverAll() {
        let loadingView: UIView = self.tabBarController?.view ?? self.view
        STLoadingView.show(in: loadingView)
        self.viewModel.recoverAll(completion: { [weak self] error in
            STLoadingView.hide(in: loadingView)
            if let error = error {
                self?.showError(error: error)
            } else {
                self?.setSelectionMode(isSelectionMode: false)
            }
        })
    }
                
}

extension STTrashVC: INavigationAnimatorSourceVC {
    
    func navigationAnimator(sendnerItem animator: STNavigationAnimator.TransitioningOperation) -> Any? {
        return self.selectedItem
    }
    
    func navigationAnimator(sourceView animator: STNavigationAnimator.TransitioningOperation, sendnerItem sendner: Any?) -> INavigationAnimatorSourceView? {
        
        guard let selectedItem = sendner as? STLibrary.TrashFile, let indexPath = self.dataSource.indexPath(at: selectedItem) else {
            return nil
        }
        
        if animator.operation == .pop {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            self.collectionView.layoutIfNeeded()
        }
        
        guard let cell = self.collectionView.cellForItem(at: indexPath) as? STTrashCollectionViewCell else {
            return nil
        }
        
        return cell.animatorSourceView
    }
    
}

extension STTrashVC: STFilesActionTabBarAccessoryViewDataSource {
    
    enum ActionType: StringPointer {
        case deleteAll
        case recoverAll
        case delete
        case recover
        
        var stringValue: String {
            switch self {
            case .deleteAll:
                return "deleteAll"
            case .recoverAll:
                return "recoverAll"
            case .delete:
                return "delete"
            case .recover:
                return "recover"
            }
        }
    }
    
    func accessoryView(actions accessoryView: STFilesActionTabBarAccessoryView) -> [STFilesActionTabBarAccessoryView.ActionItem] {
        
        var result = [STFilesActionTabBarAccessoryView.ActionItem]()
        
        if self.isSelectionMode {
            let trash = STFilesActionTabBarAccessoryView.ActionItem.trash(identifier: ActionType.delete) { [weak self] _, _ in
                self?.didSelectedTrash()
            }
            result.append(trash)
            let recover = STFilesActionTabBarAccessoryView.ActionItem.recover(identifier: ActionType.recover) { [weak self] _, _ in
                self?.didSelectedRecover()
            }
            result.append(recover)
            
        } else {
            
            let deleteAll = STFilesActionTabBarAccessoryView.ActionItem.deleteAll(identifier: ActionType.deleteAll) { [weak self] _, _ in
                self?.didSelectedDeleteAll()
            }
            result.append(deleteAll)
            
            let recoverAll = STFilesActionTabBarAccessoryView.ActionItem.recoverAll(identifier: ActionType.recoverAll) { [weak self] _, _ in
                self?.didSelectedRecoverAll()
            }
            result.append(recoverAll)
            
        }
        
        return result
    }
    
}
