//
//  STGalleryCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/15/21.
//

import UIKit
import StingleRoot

class STGalleryCollectionViewCell: UICollectionViewCell, ISelectionCollectionViewCell {
        
    @IBOutlet weak private var icRemoteImageView: UIImageView!
    @IBOutlet weak private var checkMarkImageView: UIImageView!
    @IBOutlet weak private var videoDurationLabel: UILabel!
    @IBOutlet weak private var imageView: STImageView!
    @IBOutlet weak private var videoInfoBgView: STView!
    
    private var currentImageIdentifier: String?

    var animatorSourceView: INavigationAnimatorSourceView {
        return self.imageView
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.alpha = self.isHighlighted ? 0.7 : 1
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.setSelected(isSelected: self.isSelected)
        }
    }
        
    override func prepareForReuse() {
        super.prepareForReuse()
        self.isSelected = false
        self.setSelected(isSelected: false)
        self.currentImageIdentifier = nil
    }

    func configure(model viewItem: STGalleryVC.CellModel?) {
        // Only (re)load the thumbnail when the underlying image actually changes. The FRC marks a cell
        // "reloaded" for metadata-only updates too (e.g. isSynched flipping after upload), and a bare
        // setImage would needlessly clear + re-fetch the same thumbnail — multiplied across every
        // visible cell on a sync reload. The identifier encodes file/version/remote-or-local, so it
        // changes exactly when the thumbnail does.
        let newImageIdentifier = viewItem?.image?.identifier
        if newImageIdentifier != self.currentImageIdentifier {
            self.imageView.setImage(viewItem?.image, placeholder: nil)
            self.currentImageIdentifier = newImageIdentifier
        }
        self.videoDurationLabel.text = viewItem?.videoDuration
        self.videoInfoBgView.isHidden = viewItem?.videoDuration == nil
        self.icRemoteImageView.isHidden = viewItem?.isRemote ?? false
        
        self.setSelected(isSelected: self.isSelected)
        self.setSelectedMode(mode: (viewItem?.selectedMode ?? false))
    }
    
    func setSelected(isSelected: Bool) {
        let image = isSelected ? UIImage(named: "ic_mark") : UIImage(named: "ic_un_mark")
        self.checkMarkImageView.image = image
    }
    
    func setSelectedMode(mode: Bool) {
        self.checkMarkImageView.isHidden = !mode
    }
    
}
