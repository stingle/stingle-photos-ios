//
//  STSettingsSliderTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/3/21.
//

import UIKit

extension STSettingsSliderTableViewCell {
    
    struct Model: ISettingsTableViewCellModel {
        let image: UIImage
        let title: String?
        var subTitle: String?
        var value: Float
        var isEnabled: Bool
    }
    
}

class STSettingsSliderTableViewCell: STSettingsTableViewCell<STSettingsSliderTableViewCell.Model> {

    @IBOutlet weak private var iconImageView: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
    @IBOutlet weak private var slider: UISlider!
    
    //MARK: - User action
    
    @IBAction private func didChangeSlider(_ sender: Any) {
        guard var model =  self.cellModel else {
            return
        }
        model.value = self.slider.value
        self.delegate?.securityCel(didSlide: self, model: model, value: self.slider.value)
    }
    
    override func configure(model: Model?) {
        super.configure(model: model)
        self.iconImageView.image = model?.image
        self.titleLabel.text = model?.title
        self.subTitleLabel.text = model?.subTitle
        self.slider.value = model?.value ?? .zero
        
        self.titleLabel.isHidden = self.titleLabel.text == nil
        self.subTitleLabel.isHidden = self.subTitleLabel.text == nil
        
        let isEnabled = model?.isEnabled ?? false
        self.slider.isEnabled = isEnabled
        self.contentView.alpha = isEnabled ? 1 : 0.7
    }
    
    func updateSubTitle(_ subTitle: String?) {
        self.cellModel?.subTitle = subTitle
        self.subTitleLabel.text = subTitle
        self.subTitleLabel.isHidden = self.subTitleLabel.text == nil
    }
    
}
