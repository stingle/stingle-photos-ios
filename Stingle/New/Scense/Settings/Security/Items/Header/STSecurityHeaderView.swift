//
//  STSecurityHeaderView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

class STSecurityHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak private var titleLabel: UILabel!
    
    func configure(title: String?) {
        self.titleLabel.text = title
    }
    
}
