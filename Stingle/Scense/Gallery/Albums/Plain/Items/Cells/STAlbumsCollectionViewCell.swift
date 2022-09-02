//
//  STAlbumsCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/14/21.
//

import UIKit
import StingleRoot

protocol STAlbumsCollectionViewCellDelegate: AnyObject {
    func albumsCell(didSelectDelete cell: STAlbumsCollectionViewCell)
}

class STAlbumsCollectionViewCell: UICollectionViewCell, IViewDataSourceCell {
    
    @IBOutlet private weak var imageView: STImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var itemsCountLabel: UILabel!
    @IBOutlet private weak var deleteButton: UIButton!
    
    weak var delegate: STAlbumsCollectionViewCellDelegate?
    
    override var isHighlighted: Bool {
        didSet {
            self.alpha = self.isHighlighted ? 0.7 : 1
        }
    }
        
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view != nil, let button = self.deleteButton, !button.isHidden, button.bounds.contains(self.convert(point, to: button)) {
            return button
        }
        return view
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) {
            return true
        }
        guard let button = self.deleteButton, !button.isHidden, button.bounds.contains(self.convert(point, to: button)) else {
            return false
        }
        return true
    }
   
    func configure(model: STAlbumsVC.ViewModel.CellModel?) {
        self.imageView.setImage(model?.image, placeholder: model?.placeholder)
        self.nameLabel.text = model?.title
        self.itemsCountLabel.text = model?.subTille
        self.deleteButton.isHidden = !(model?.isEditMode ?? false)
    }
    
    @IBAction private func didSelectDeleteButton(_ sender: Any) {
        self.delegate?.albumsCell(didSelectDelete: self)
    }
    
}
