//
//  STAlbumsSharedCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/26/21.
//

import UIKit
import StingleRoot

class STAlbumsSharedCollectionViewCell: UICollectionViewCell, IViewDataSourceCell {
   
    @IBOutlet weak private var albumImageView: STImageView!
    @IBOutlet weak private var iconIsOwner: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var membersLabel: UILabel!
    @IBOutlet weak private var moreMembersLabel: UILabel!
    
    override var isHighlighted: Bool {
        didSet {
            self.alpha = self.isHighlighted ? 0.7 : 1
        }
    }

    func configure(model: STAlbumsSharedVC.ViewModel.CellModel?) {
        self.albumImageView.setImage(model?.image, placeholder: model?.placeholder)
        self.titleLabel.text = model?.title
        self.membersLabel.text = model?.members
        self.moreMembersLabel.text = model?.moreMembers
        self.iconIsOwner.image = model?.iconIsOwner
    }
    
}
