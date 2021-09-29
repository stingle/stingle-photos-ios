//
//  STmenuMasterTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/5/21.
//

import UIKit

class STMenuMasterTableViewCell: UITableViewCell {

    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectedBackgroundView = UIView()
        self.selectedBackgroundView?.backgroundColor = UIColor.primaryTransparent
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let color = selected ? UIColor.appPrimary : UIColor.appSecondaryText
        self.iconImageView?.tintColor = color
        self.titleLabel?.textColor = color
    }
    
    func configure(model: STMenuMasterVC.Menu.Cell?) {
        self.titleLabel.text = model?.name
        self.iconImageView.image = model?.icon
    }
    
}
