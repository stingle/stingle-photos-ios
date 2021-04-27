//
//  STTrashCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import UIKit

class STTrashCollectionViewCell: UICollectionViewCell, IViewDataSourceCell {
   
    typealias Model = STTrashVC.CellModel

    @IBOutlet weak private var icRemoteImageView: UIImageView!
    @IBOutlet weak private var videoDurationLabel: UILabel!
    @IBOutlet weak private var imageView: STImageView!
    
    override var isHighlighted: Bool {
        didSet {
            self.alpha = self.isHighlighted ? 0.7 : 1
        }
    }
    
    func configure(model viewItem: STTrashVC.CellModel?) {
        self.imageView.setImage(viewItem?.image, placeholder: nil)
        self.videoDurationLabel.text = viewItem?.videoDuration
        self.icRemoteImageView.isHidden = viewItem?.isRemote ?? false
    }
    
}
