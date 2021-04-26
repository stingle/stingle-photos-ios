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
        
        func cellModel(for indexPath: IndexPath, data: STLibrary.TrashFile) -> STTrashVC.CellModel {
            let image = STImageView.Image(file: data, isThumb: true)
            var videoDurationStr: String? = nil
            if let duration = data.decryptsHeaders.file?.videoDuration, duration > 0 {
                videoDurationStr = TimeInterval(duration).toString()
            }
            return CellModel(image: image,
                             name: data.file,
                             videoDuration: videoDurationStr,
                             isRemote: data.isRemote)
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
    
    private let viewModel = STTrashVM()

    override func configureLocalize() {
        super.configureLocalize()
        self.navigationItem.title = "trash".localized
        self.navigationController?.tabBarItem.title = "trash".localized
        
        self.emptyDataTitleLabel?.text = "empy_trash_title".localized
        self.emptyDataSubTitleLabel?.text = "empy_trash_message".localized
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
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 5 : 3
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

}
