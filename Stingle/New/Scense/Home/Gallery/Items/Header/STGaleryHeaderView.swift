//
//  STGaleryHeaderView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/15/21.
//

import UIKit

class STGaleryHeaderView: UICollectionReusableView {

    @IBOutlet weak private var titleLabel: UILabel!
    
    func configure(title: String?) {
        self.titleLabel.text = title
    }
    
}
