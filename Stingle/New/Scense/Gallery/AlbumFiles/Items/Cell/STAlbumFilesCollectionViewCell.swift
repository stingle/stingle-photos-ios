//
//  STAlbumFilesCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/19/21.
//

import UIKit

class STAlbumFilesCollectionViewCell: UICollectionViewCell, IViewDataSourceCell {

    @IBOutlet weak private var checkMarkImageView: UIImageView!
    @IBOutlet weak private var icRemoteImageView: UIImageView!
    @IBOutlet weak private var videoDurationLabel: UILabel!
    @IBOutlet weak private var imageView: STImageView!
    
    override var isHighlighted: Bool {
        didSet {
            self.alpha = self.isHighlighted ? 0.7 : 1
        }
    }
   
    func configure(model viewItem: STAlbumFilesVC.CellModel?) {
        self.imageView.setImage(viewItem?.image, placeholder: nil)
        self.videoDurationLabel.text = viewItem?.videoDuration
        self.icRemoteImageView.isHidden = viewItem?.isRemote ?? false
        
        self.checkMarkImageView.isHidden = !(viewItem?.selectedMode ?? true)
        self.setSelected(isSelected: viewItem?.isSelected ?? false)
    }
    
    func setSelected(isSelected: Bool) {
        let image = isSelected ? UIImage(named: "ic_mark") : UIImage(named: "ic_un_mark")
        self.checkMarkImageView.image = image
    }
    
}
