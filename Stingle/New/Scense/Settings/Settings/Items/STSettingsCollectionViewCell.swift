//
//  STSettingsCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/13/21.
//

import UIKit

class STSettingsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var imageView: UIImageView!
    
    override var isHighlighted: Bool {
        didSet {
            self.alpha = self.isHighlighted ? 0.7 : 1
        }
    }
    
    func configure(viewModel: STSettingsVC.CellItem) {
        self.titleLabel.text = viewModel.title
        self.imageView.image = viewModel.image
    }
    
}
