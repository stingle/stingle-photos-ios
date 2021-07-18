//
//  STSecuritySwichTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

extension STSecuritySwichTableViewCell {
    
    struct Model: ISecurityTableViewCellModel {
        let itemType: STSecurityVC.ItemType
        let image: UIImage
        let title: String?
        let subTitle: String?
        var isOn: Bool
        let isEnabled: Bool
    }
    
}

class STSecuritySwichTableViewCell: STSecurityVCTableViewCell<STSecuritySwichTableViewCell.Model> {

    @IBOutlet weak private var iconImageView: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
    @IBOutlet weak private var swicher: UISwitch!

    override func configure(model: Model) {
        self.iconImageView.image = model.image
        self.titleLabel.text = model.title
        self.subTitleLabel.text = model.subTitle
        self.swicher.isOn = model.isOn
        self.swicher.isEnabled = model.isEnabled
        self.contentView.alpha = model.isEnabled ? 1 : 0.7
        
        self.titleLabel.isHidden = model.title == nil
        self.subTitleLabel.isHidden = model.subTitle == nil
    }
    
    
    //MARK: - User Action
    
    @IBAction private func didSelectSwicher(_ sender: Any) {
        guard let model =  self.model else {
            return
        }
        self.delegate?.securityCel(didSelectSwich: self, model: model, isOn: self.swicher.isOn)
    }
    
}
