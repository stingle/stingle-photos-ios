//
//  STTrashCollectionViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import UIKit
import StingleRoot

class STTrashCollectionViewCell: UICollectionViewCell, ISelectionCollectionViewCell {

    typealias Model = STTrashVC.CellModel

    @IBOutlet weak private var icRemoteImageView: UIImageView!
    @IBOutlet weak private var videoDurationLabel: UILabel!
    @IBOutlet weak private var imageView: STImageView!
    @IBOutlet weak private var checkMarkImageView: UIImageView!
    @IBOutlet weak private var videoInfoBgView: STView!
    
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
    }
    
    func configure(model viewItem: STTrashVC.CellModel?) {
        self.imageView.setImage(viewItem?.image, placeholder: nil)
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
