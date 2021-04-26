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
    
    override var isHighlighted: Bool {
        didSet {
            self.alpha = self.isHighlighted ? 0.7 : 1
        }
    }
   
    func configure(model: STAlbumsVC.ViewModel.CellModel?) {
        self.imageView.setImage(model?.image, placeholder: model?.placeholder)
        self.nameLabel.text = model?.title
        self.itemsCountLabel.text = model?.subTille
    }
    
}
