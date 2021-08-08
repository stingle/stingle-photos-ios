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
        
        var selectedFileNames = Set<String>()
        var isSelectedMode = false
        
        func cellModel(for indexPath: IndexPath, data: STLibrary.TrashFile) -> STTrashVC.CellModel {
            let image = STImageView.Image(file: data, isThumb: true)
            var videoDurationStr: String? = nil
            if let duration = data.decryptsHeaders.file?.videoDuration, duration > 0 {
                videoDurationStr = TimeInterval(duration).toString()
            }
            return CellModel(image: image,
                             name: data.file,
                             videoDuration: videoDurationStr,
                             isRemote: data.isRemote,
                             selectedMode: self.isSelectedMode,
                             isSelected: self.selectedFileNames.contains(data.file))
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
        let isSelected: Bool
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


class STTrashVC: STFilesViewController<STTrashVC.ViewModel> {
    
    @IBOutlet weak private var selectButtonItem: UIBarButtonItem!
    
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
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 5 : layoutEnvironment.container.contentSize.width > layoutEnvironment.container.contentSize.height ? 4 : 3
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
    
    //MARK: - UserAction
    
    @IBAction private func didSelectSelecedButtonItem(_ sender: UIBarButtonItem) {
        self.setSelectedMode(isSelectedMode: !self.dataSource.viewModel.isSelectedMode)
    }
    
    //MARK: - Private methods
    
    private func setSelectedMode(isSelectedMode: Bool) {
        guard isSelectedMode != self.dataSource.viewModel.isSelectedMode else {
            return
        }
        self.dataSource.viewModel.selectedFileNames.removeAll()
        self.dataSource.viewModel.isSelectedMode = isSelectedMode
        self.updateTabBarAccessoryView()
        self.selectButtonItem.title = self.dataSource.viewModel.isSelectedMode ? "cancel".localized : "select".localized
        self.collectionView.reloadData()
        self.updateSelectedItesmCount()
    }
    
    private func updateTabBarAccessoryView() {
        self.accessoryView.reloadData()
    }
    
    private func updateSelectedItesmCount() {
        let count = self.dataSource.viewModel.selectedFileNames.count
        let title = self.dataSource.viewModel.isSelectedMode ? count == 0 ? "select_items".localized : String(format: "selected_items_count".localized, "\(count)") : nil
        self.accessoryView.title = title
        let isEnabled = self.dataSource.viewModel.isSelectedMode ? count != .zero : !self.dataSource.isEmptyData
        self.accessoryView.setEnabled(isEnabled: isEnabled)
    }
    
    private func didSelectedTrash() {
        guard !self.dataSource.viewModel.selectedFileNames.isEmpty else {
            return
        }
        
        let fileNames = [String](self.dataSource.viewModel.selectedFileNames)
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
                    self?.setSelectedMode(isSelectedMode: false)
                }
            })
        })
        
    }
    
    private func didSelectedRecover() {
        guard !self.dataSource.viewModel.selectedFileNames.isEmpty else {
            return
        }
        
        let fileNames = [String](self.dataSource.viewModel.selectedFileNames)
        let files = self.viewModel.getFiles(fileNames: fileNames)
        let loadingView: UIView = self.tabBarController?.view ?? self.view

        STLoadingView.show(in: loadingView)
        self.viewModel.recover(files: files, completion: { [weak self] error in
            STLoadingView.hide(in: loadingView)
            if let error = error {
                self?.showError(error: error)
            } else {
                self?.setSelectedMode(isSelectedMode: false)
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
                    self?.setSelectedMode(isSelectedMode: false)
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
                self?.setSelectedMode(isSelectedMode: false)
            }
        })
    }
    
    private func setSelectedItem(for indexPath: IndexPath) {
        guard let albumFile =  self.dataSource.object(at: indexPath) else {
            return
        }
        var isSelected = false
        if self.dataSource.viewModel.selectedFileNames.contains(albumFile.file) {
            self.dataSource.viewModel.selectedFileNames.remove(albumFile.file)
            isSelected = false
        } else {
            self.dataSource.viewModel.selectedFileNames.insert(albumFile.file)
            isSelected = true
        }
        let cell = (collectionView.cellForItem(at: indexPath) as? STTrashCollectionViewCell)
        cell?.setSelected(isSelected: isSelected)
        self.updateSelectedItesmCount()
    }
            
}

extension STTrashVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.dataSource.viewModel.isSelectedMode {
            self.setSelectedItem(for: indexPath)
        } else {
            guard let file = self.dataSource.object(at: indexPath) else {
                return
            }
            let vc = STFileViewerVC.create(trash: file, sortDescriptorsKeys: [#keyPath(STCDFile.dateCreated)])
            self.show(vc, sender: nil)
        }
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
        
        if self.dataSource.viewModel.isSelectedMode {
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
