//
//  STMoveAlbumFilesCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/8/21.
//

import UIKit

class STMoveAlbumFilesCell: UICollectionViewCell, IViewDataSourceCell {
    
    @IBOutlet private weak var imageView: STImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var deleteButton: UIButton!

    func configure(model: STMoveAlbumFilesVC.ViewModel.CellModel?) {
        self.imageView.setImage(model?.image, placeholder: model?.placeholder)
        self.nameLabel.text = model?.title
        self.descriptionLabel.text = model?.subTille
    }

}
