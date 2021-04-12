//
//  STGalleryCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/15/21.
//

import UIKit



class STGalleryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak private var icRemoteImageView: UIImageView!
    @IBOutlet weak private var videoDurationLabel: UILabel!
    @IBOutlet weak private var imageView: STImageView!
    
    func configure(viewItem: STGalleryVC.ViewItem?) {
        self.imageView.setImage(viewItem?.image, placeholder: nil)
        self.videoDurationLabel.text = viewItem?.videoDuration
        self.icRemoteImageView.isHidden = viewItem?.isRemote ?? false
    }
    
}
