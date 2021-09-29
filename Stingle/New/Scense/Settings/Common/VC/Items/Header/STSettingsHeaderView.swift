//
//  STSecurityHeaderView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

struct STSettingsHeaderViewModel {
    var title: String?
}

class STSettingsHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak private var titleLabel: UILabel!
    
    func configure(title: String?) {
        self.titleLabel.text = title
    }
    
    func configure(model: STSettingsHeaderViewModel?) {
        self.configure(title: model?.title)
    }
    
}
