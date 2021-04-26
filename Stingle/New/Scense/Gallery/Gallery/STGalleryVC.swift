//
//  STGalleryVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/14/21.
//

import UIKit
import Photos

extension STGalleryVC {
    
    struct ViewModel: ICollectionDataSourceViewModel {
                              
        typealias Header = STGaleryHeaderView
        typealias Cell = STGalleryCollectionViewCell
        typealias CDModel = STCDFile
        
        func cellModel(for indexPath: IndexPath, data: STLibrary.File) -> CellModel {
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
        
        func headerModel(for indexPath: IndexPath, section: String) -> HeaderModel {
            return HeaderModel(text: section)
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
                return "STGalleryCollectionViewCell"
            case .header:
                return "STGaleryHeaderView"
            }
        }
        
        var identifier: String {
            switch self {
            case .cell:
                return "STGalleryCollectionViewCellID"
            case .header:
                return "STGaleryHeaderViewID"
            }
        }
    }
        
}

class STGalleryVC: STFilesViewController<STGalleryVC.ViewModel> {
        
    @IBOutlet weak var syncBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var syncView: STGallerySyncView!
    private var viewModel = STGalleryVM()
    
    private lazy var pickerHelper: STImagePickerHelper = {
        return STImagePickerHelper(controller: self)
    }()
    
    @IBAction func didSelectSyncButton(_ sender: Any) {
        let controller = self.storyboard!.instantiateViewController(identifier: "Popover")
        controller.modalPresentationStyle = .popover
        let popController = controller.popoverPresentationController
        popController?.permittedArrowDirections = .any
        popController?.barButtonItem = self.syncBarButtonItem
        popController?.delegate = self
        self.showDetailViewController(controller, sender: nil)
    }
        
    //MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.sync()
    }
    
    override func createDataSource() -> STCollectionViewDataSource<ViewModel> {
        let dbDataSource = self.viewModel.createDBDataSource()
        let viewModel = ViewModel()
        return STCollectionViewDataSource<ViewModel>(dbDataSource: dbDataSource,
                                                     collectionView: self.collectionView,
                                                     viewModel: viewModel)
    }
        
    override func configureLocalize() {
        super.configureLocalize()
        self.navigationItem.title = "gallery".localized
        self.navigationController?.tabBarItem.title = "gallery".localized
        
        self.emptyDataTitleLabel?.text = "empy_gallery_title".localized
        self.emptyDataSubTitleLabel?.text = "empy_gallery_message".localized  
    }
    
    override func refreshControlDidRefresh() {
        self.viewModel.sync()
    }
    
    //MARK: - User action
    
    @IBAction private func didSelectOpenImagePicker(_ sender: Any) {
        self.pickerHelper.openPicker()
    }

    //MARK: - Layout

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

extension STGalleryVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let cell = collectionView.cellForItem(at: indexPath) as? STGalleryCollectionViewCell
//        let item = self.viewModel.item(at: indexPath)
    }
    
}

extension STGalleryVC: STImagePickerHelperDelegate {
    
    func pickerViewController(_ imagePickerHelper: STImagePickerHelper, didPickAssets assets: [PHAsset]) {
        self.viewModel.upload(assets: assets)
    }
    
}

extension STGalleryVC: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}
