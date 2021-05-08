//
//  STMoveAlbumFilesVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/8/21.
//

import UIKit

extension STMoveAlbumFilesVC {
    
    struct ViewModel: ICollectionDataSourceViewModel, IAlbumsViewModel {
                       
        typealias Cell = STMoveAlbumFilesCell
        typealias Header = STMoveAlbumFilesHeader
        typealias CDModel = STCDAlbum
        
        struct CellModel: IViewDataSourceCellModel {
            let identifier: Identifier = .cell
            let image: STImageView.Image?
            let placeholder: UIImage?
            let title: String?
            let subTille: String?
            let isEnabled: Bool
        }
        
        struct HeaderModel: IViewDataSourceHeaderModel {
            let identifier: Identifier = .header
        }
        
        enum Identifier: CaseIterable, IViewDataSourceItemIdentifier {
            case cell
            case header
            
            var nibName: String {
                switch self {
                case .cell:
                    return "STMoveAlbumFilesCell"
                case .header:
                    return "STMoveAlbumFilesHeader"
                }
            }
            
            var identifier: String {
                switch self {
                case .cell:
                    return "STMoveAlbumFilesCell"
                case .header:
                    return "STMoveAlbumFilesHeader"
                }
            }
        }
        
        static let imageBlankImageName = "__b__"
        
        var delegate: STAlbumsDataSourceViewModelDelegate?
        
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
            
            return CellModel(image: image,
                             placeholder: placeholder,
                             title: title,
                             subTille: subTille,
                             isEnabled: false)
            
        }
        
        func headerModel(for indexPath: IndexPath, section: String) -> HeaderModel {
            return HeaderModel()
        }
    }
    
}


class STMoveAlbumFilesVC: STFilesViewController<STMoveAlbumFilesVC.ViewModel> {

    @IBOutlet weak var deleeFileLabel: UILabel!
    
    //MARK: - User action
    
    @IBAction func didSelectCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        
    }

}
