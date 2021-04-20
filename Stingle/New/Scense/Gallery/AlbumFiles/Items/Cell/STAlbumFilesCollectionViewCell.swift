//
//  STAlbumFilesCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/19/21.
//

import UIKit

class STAlbumFilesCollectionViewCell: UICollectionViewCell, IViewDataSourceCell {

    @IBOutlet weak private var icRemoteImageView: UIImageView!
    @IBOutlet weak private var videoDurationLabel: UILabel!
    @IBOutlet weak private var imageView: STImageView!
   
    func configure(model viewItem: STAlbumFilesVC.CellModel?) {
        self.imageView.setImage(viewItem?.image, placeholder: nil)
        self.videoDurationLabel.text = viewItem?.videoDuration
        self.icRemoteImageView.isHidden = viewItem?.isRemote ?? false
    }
    
}
