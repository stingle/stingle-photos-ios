//
//  STGaleryHeaderView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/15/21.
//

import UIKit

class STGaleryHeaderView: UICollectionReusableView, IViewDataSourceHeader {

    @IBOutlet weak private var titleLabel: UILabel!
    
    func configure(model: STGalleryVC.HeaderModel?) {
        self.titleLabel.text = model?.text
    }
    
}
