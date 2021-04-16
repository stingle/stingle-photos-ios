//
//  STTrashHeaderView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/13/21.
//

import UIKit

class STTrashHeaderView: UICollectionReusableView {

    @IBOutlet weak private var titleLabel: UILabel!
    
    func configure(title: String?) {
        self.titleLabel.text = title
    }
    
}
