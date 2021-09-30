//
//  STSharedAlbumSettingsNameCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/17/21.
//

import UIKit

struct STAlbumSettingsNameCellModel: ISharedAlbumSettingsItemModel {
    var itemType: STSharedAlbumSettingsVC.TableItem = .nameCell
    var id: Any? = nil
    let title: String?
    let name: String?
    let buttonTitle: String?
}

class STAlbumSettingsNameCell: STSharedAlbumSettingsBaseCell<STAlbumSettingsNameCellModel> {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var shareButton: STButton!
    
    //MARK: - Private
        
    override func configure(viewModel: STAlbumSettingsNameCellModel?) {
        super.configure(viewModel: viewModel)
        self.titleLabel.text = viewModel?.title
        self.nameLabel.text = viewModel?.name
        self.shareButton.setTitle(viewModel?.buttonTitle, for: .normal)
    }
    
    @IBAction private func didSelectShareButton(_ sender: Any) {
        guard let viewModel = self.model else {
            return
        }
        self.delegate?.sharedAlbumSettingsCell(cell: self, didSelectShare: viewModel)
    }
    
}
