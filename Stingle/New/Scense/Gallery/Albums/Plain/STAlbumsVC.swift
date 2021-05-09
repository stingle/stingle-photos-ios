//
//  STAlbumsVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import UIKit

extension STAlbumsVC {
    
    struct ViewModel: ICollectionDataSourceNoHeaderViewModel, IAlbumsViewModel {
        
        typealias Cell = STAlbumsCollectionViewCell
        typealias CDModel = STCDAlbum
        
        static let imageBlankImageName = "__b__"
        weak var delegate: STAlbumsDataSourceViewModelDelegate?
        var isEditMode = false
        
        enum Identifier: CaseIterable, IViewDataSourceItemIdentifier {
            case album
            
            var nibName: String {
                switch self {
                case .album:
                    return "STAlbumsCollectionViewCell"
                }
            }
            
            var identifier: String {
                switch self {
                case .album:
                    return "STAlbumsCollectionViewCellID"
                }
            }
        }
        
        struct HeaderModel {
            let text: String?
        }
        
        struct CellModel: IViewDataSourceCellModel {
            let identifier: Identifier = .album
            let image: STImageView.Image?
            let placeholder: UIImage?
            let title: String?
            let subTille: String?
            let isEditMode: Bool
        }
                
        func cellModel(for indexPath: IndexPath, data: STLibrary.Album) -> CellModel {
            let metadata = self.delegate?.viewModel(albumMedadataFor: data)
            let placeholder = UIImage(named: "ic_album")
            var image: STImageView.Image?
            
            switch data.cover {
            case ViewModel.imageBlankImageName:
                break
            default:
                if let file = metadata?.file {
                    image = STImageView.Image(album: data, albumFile: file, isThumb: true)
                }
            }
            let title = data.albumMetadata?.name
            let subTille = String(format: "items_count".localized, "\(metadata?.countFiles ?? 0)")
            return CellModel(image: image, placeholder: placeholder, title: title, subTille: subTille, isEditMode: self.isEditMode)
        }
    }
    
}

class STAlbumsVC: STFilesViewController<STAlbumsVC.ViewModel> {
        
    private let viewModel = STAlbumsVM()
    private let segueIdentifierAlbumFiles = "AlbumFiles"
    
    @IBOutlet weak private var editBarButtonItem: UIBarButtonItem!
    
    override func configureLocalize() {
        self.navigationItem.title = "albums".localized
        self.navigationController?.tabBarItem.title = "albums".localized
        self.emptyDataTitleLabel?.text = "empy_albums_title".localized
        self.emptyDataSubTitleLabel?.text = "empy_albums_message".localized
        self.editBarButtonItem.title = "edit".localized
    }
    
    override func createDataSource() -> STCollectionViewDataSource<STAlbumsVC.ViewModel> {
        let viewModel = ViewModel()
        let predicate = NSPredicate(format: "isHidden == %i", false)
        let dataSource = STAlbumsDataSource(collectionView: self.collectionView, predicate: predicate, viewModel: viewModel)
        return dataSource
    }
    
    override func refreshControlDidRefresh() {
        self.viewModel.sync()
    }
     
    override func layoutSection(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let inset: CGFloat = 14
        let lineCount = layoutEnvironment.traitCollection.isIpad() ? 3 : 2
        let item = self.dataSource.generateCollectionLayoutItem()
        let itemSizeWidth = (layoutEnvironment.container.contentSize.width - 2 * inset) / CGFloat(lineCount)
        let itemSizeHeight = itemSizeWidth
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemSizeHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: lineCount)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        group.interItemSpacing = .fixed(inset)
                
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
        section.interGroupSpacing = inset
        section.removeContentInsetsReference(safeAreaInsets: self.collectionView.window?.safeAreaInsets)
        return section
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.segueIdentifierAlbumFiles, let albumFilesVC = segue.destination as? STAlbumFilesVC, let album = sender as? STLibrary.Album {
            albumFilesVC.album = album
        }
    }
    
    override func dataSource(didConfigureCell dataSource: IViewDataSource, cell: UICollectionViewCell) {
        super.dataSource(didConfigureCell: dataSource, cell: cell)
        (cell as? ViewModel.Cell)?.delegate = self
    }
    
    //MARK: - User acction
    
    @IBAction func didSeleckEditButton(_ sender: UIBarButtonItem) {
        self.dataSource.viewModel.isEditMode = !self.dataSource.viewModel.isEditMode
        let title = self.dataSource.viewModel.isEditMode ? "done".localized : "edit".localized
        self.editBarButtonItem.title = title
        self.dataSource.reloadCollection()
    }
    
    @IBAction private func didSelectAddAlbum(_ sender: Any) {
        self.showAddAlbumAlert {[weak self] (albumName) in
            self?.createAlbum(with: albumName)
        }
    }
    
    //MARK: - Private
    
    private func showAddAlbumAlert(okAction: @escaping ((String) -> Void)) {
        let title = "create_album_title".localized
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "album_name".localized
        }
        let ok = UIAlertAction(title: "ok".localized, style: .default) { (_) in
            okAction(alert.textFields?.first?.text ?? "")
        }
        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func createAlbum(with name: String) {
        STLoadingView.show(in: self.view)
        self.viewModel.createAlbum(with: name, compliation: { [weak self] (error) in
            guard let view = self?.view else {
                return
            }
            STLoadingView.hide(in: view)
            if let error = error {
                self?.showError(error: error)
            }
        })
    }
    
    private func deleteAlbum(_ album: STLibrary.Album) {
        STLoadingView.show(in: self.view)
        self.viewModel.deleteAlbum(album: album) { [weak self] error in
            guard let view = self?.view else {
                return
            }
            STLoadingView.hide(in: view)
            if let error = error {
                self?.showError(error: error)
            }
        }
    }
    
    func showDeleteAlbumAlert(_ album: STLibrary.Album) {
        let title = String(format: "delete_album_alert_title".localized, album.albumMetadata?.name ?? "")
        let message = String(format: "delete_album_alert_message".localized, album.albumMetadata?.name ?? "")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "ok".localized, style: .default) { [weak self] (_) in
            self?.deleteAlbum(album)
        }
        let cancel = UIAlertAction(title: "cancel".localized, style: .cancel)
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }

}

extension STAlbumsVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let album = self.dataSource.object(at: indexPath) else {
            return
        }
        self.performSegue(withIdentifier: self.segueIdentifierAlbumFiles, sender: album)
    }
    
}

extension STAlbumsVC: STAlbumsCollectionViewCellDelegate {
    
    func albumsCell(didSelectDelete cell: STAlbumsCollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell), let album = self.dataSource.object(at: indexPath) else {
            return
        }
        self.showDeleteAlbumAlert(album)
    }
     
}
