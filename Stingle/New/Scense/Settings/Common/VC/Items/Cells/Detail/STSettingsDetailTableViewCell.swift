//
//  STSecurityDetailTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

extension STSettingsDetailTableViewCell {
    
    struct Model: ISettingsTableViewCellModel {
        let image: UIImage
        let title: String?
        var subTitle: String?
        var isEnabled: Bool = true
    }
    
}

class STSettingsDetailTableViewCell: STSettingsTableViewCell<STSettingsDetailTableViewCell.Model> {

    @IBOutlet weak private var iconImageView: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
    
    override func configure(model: Model?) {
        super.configure(model: model)
        self.iconImageView.image = model?.image
        self.titleLabel.text = model?.title
        self.subTitleLabel.text = model?.subTitle
        self.titleLabel.isHidden = model?.title == nil
        self.subTitleLabel.isHidden = model?.subTitle == nil
        
        let isEnabled =  model?.isEnabled ?? false
        self.contentView.alpha = isEnabled ? 1 : 0.7
    }
    
    func update(subTitle: String?) {
        self.subTitleLabel.text = subTitle
        self.titleLabel.isHidden = subTitle == nil
        self.cellModel?.subTitle = subTitle
    }
    
}
