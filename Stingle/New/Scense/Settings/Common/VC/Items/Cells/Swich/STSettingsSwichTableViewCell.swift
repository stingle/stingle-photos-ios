//
//  STSecuritySwichTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

extension STSettingsSwichTableViewCell {
    
    struct Model: ISettingsTableViewCellModel {
        let image: UIImage
        let title: String?
        let subTitle: String?
        var isOn: Bool
        let isEnabled: Bool
    }
    
}

class STSettingsSwichTableViewCell: STSettingsTableViewCell<STSettingsSwichTableViewCell.Model> {

    @IBOutlet weak private var iconImageView: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
    @IBOutlet weak private var swicher: UISwitch!

    override func configure(model: Model?) {
        super.configure(model: model)
        self.iconImageView.image = model?.image
        self.titleLabel.text = model?.title
        self.subTitleLabel.text = model?.subTitle
        self.swicher.isOn = model?.isOn ?? false
        
        let isEnabled =  model?.isEnabled ?? false
        
        self.swicher.isEnabled = isEnabled
        self.contentView.alpha = isEnabled ? 1 : 0.7
        self.titleLabel.isHidden = model?.title == nil
        self.subTitleLabel.isHidden = model?.subTitle == nil
    }
    
    
    //MARK: - User Action
    
    @IBAction private func didSelectSwicher(_ sender: Any) {
        guard let model =  self.model else {
            return
        }
        self.delegate?.securityCel(didSelectSwich: self, model: model, isOn: self.swicher.isOn)
    }
    
}
