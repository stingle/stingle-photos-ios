//
//  STAlbumsCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/14/21.
//

import UIKit

class STAlbumsCollectionViewCell: UICollectionViewCell, IViewDataSourceCell {
    
    @IBOutlet private weak var imageView: STImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var itemsCountLabel: UILabel!
   
    func configure(model: STAlbumsDataSource.ViewModel.CellModel?) {
        self.imageView.setImage(model?.image, placeholder: model?.placeholder)
        self.nameLabel.text = model?.title
        self.itemsCountLabel.text = model?.subTille
    }
    
}
