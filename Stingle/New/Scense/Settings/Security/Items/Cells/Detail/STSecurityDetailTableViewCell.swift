//
//  STSecurityDetailTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

extension STSecurityDetailTableViewCell {
    
    struct Model: ISecurityTableViewCellModel {
        let itemType: STSecurityVC.ItemType
        let image: UIImage
        let title: String?
        let subTitle: String?
    }
    
}

class STSecurityDetailTableViewCell: STSecurityVCTableViewCell<STSecurityDetailTableViewCell.Model> {

    @IBOutlet weak private var iconImageView: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
    
    override func configure(model: Model) {
        self.iconImageView.image = model.image
        self.titleLabel.text = model.title
        self.subTitleLabel.text = model.subTitle
        self.titleLabel.isHidden = model.title == nil
        self.subTitleLabel.isHidden = model.subTitle == nil
    }
    
    func update(subTitle: String?) {
        self.subTitleLabel.text = subTitle
        self.titleLabel.isHidden = subTitle == nil
    }
    
}
