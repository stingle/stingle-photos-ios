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
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleLabel: UILabel!
    @IBOutlet weak private var placeholderView: UIView!
    
    private(set) var model: STMoveAlbumFilesVC.ViewModel.CellModel?
    
    
    override var isHighlighted: Bool {
        didSet {
            let isEnabled = (self.model?.isEnabled ?? false)
            self.alpha = self.isHighlighted && isEnabled ? 0.7 : 1
        }
    }

    func configure(model: STMoveAlbumFilesVC.ViewModel.CellModel?) {
        self.model = model
        self.imageView.setImage(model?.image, placeholder: model?.placeholder)
        self.nameLabel.text = model?.name
        self.titleLabel.text = model?.title
        self.subTitleLabel.text = model?.subTille
        self.nameLabel.isHidden = model?.name == nil
        self.titleLabel.isHidden = model?.title == nil
        self.subTitleLabel.isHidden = model?.subTille == nil
        let isEnabled = (model?.isEnabled ?? false)
        self.placeholderView.alpha = isEnabled ? 1 : 0.3
    }

}
