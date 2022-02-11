//
//  STAspectRatioCell.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 1/31/22.
//

import UIKit

class STAspectRatioCell: UICollectionViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var selectedView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectedView.layer.cornerRadius = 5.0
        self.selectedView.backgroundColor = UIColor(white: 0.56, alpha: 1)
    }

    var title: String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    override var isSelected: Bool {
        didSet {
            self.selectedView.isHidden = !self.isSelected
        }
    }

}
