//
//  STAboutDetailTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/28/21.
//

import UIKit

class STAboutDetailTableViewCell: STAboutBaseTableViewCell<STAboutVC.DataModel.DetailItem> {

    @IBOutlet weak private var titleLabel: UILabel!
    
    override func configure(model: STAboutVC.DataModel.DetailItem?) {
        super.configure(model: model)
        self.titleLabel.text = model?.title
    }
    
}
