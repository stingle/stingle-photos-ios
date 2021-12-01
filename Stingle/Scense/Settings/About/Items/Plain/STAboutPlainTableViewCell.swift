//
//  STAboutPlainTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/28/21.
//

import UIKit

class STAboutPlainTableViewCell: STAboutBaseTableViewCell<STAboutVC.DataModel.PlainItem> {

    @IBOutlet weak private var tleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
        
    override func configure(model: STAboutVC.DataModel.PlainItem?) {
        super.configure(model: model)
        self.tleLabel.text = model?.title
        self.subTitleLabel.text = model?.subTitle
    }
    
}
