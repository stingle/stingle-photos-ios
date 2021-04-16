//
//  STTrashCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import UIKit

class STTrashCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak private var icRemoteImageView: UIImageView!
    @IBOutlet weak private var videoDurationLabel: UILabel!
    @IBOutlet weak private var imageView: STImageView!
    
    func configure(viewItem: STTrashVC.ViewItem?) {
        self.imageView.setImage(viewItem?.image, placeholder: nil)
        self.videoDurationLabel.text = viewItem?.videoDuration
        self.icRemoteImageView.isHidden = viewItem?.isRemote ?? false
    }
    
    
}
