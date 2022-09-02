//
//  STTrashHeaderView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import UIKit
import StingleRoot

class STTrashHeaderView: UICollectionReusableView, IViewDataSourceHeader {

    @IBOutlet weak private var titleLabel: UILabel!
    
    func configure(model: STTrashVC.HeaderModel?) {
        self.titleLabel.text = model?.text
    }

    
}
