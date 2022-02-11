//
//  STFilterCell.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 12/27/21.
//

import UIKit

class STFilterCell: UICollectionViewCell {

    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var slider: STFilterValueSlider!
    @IBOutlet weak private var valueLabel: UILabel!

    var image: UIImage? {
        get {
            return self.imageView.image
        }
        set {
            self.imageView.image = newValue
        }
    }

    var value: CGFloat {
        get {
            return self.slider.value
        }
        set {
            self.slider.value = newValue
            self.valueLabel.text = "\(Int(self.value))"
            if newValue >= 0 {
                self.valueLabel.textColor = UIColor(red: 249 / 255.0, green: 214 / 255.0, blue: 74 / 255.0, alpha: 1)
            } else {
                self.valueLabel.textColor = UIColor.white
            }
        }
    }

    var showValue: Bool = false {
        didSet {
            self.imageView.isHidden = self.showValue
            self.valueLabel.isHidden = !self.showValue
        }
    }

    override var isSelected: Bool {
        didSet {
            if !self.isSelected {
                self.showValue = false
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageView.tintColor = .white
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.slider.value = 0.0
    }
}
