//
//  STlbumFilesHeaderView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/19/21.
//

import UIKit

class STAlbumFilesHeaderView: UICollectionReusableView, IViewDataSourceHeader {

    @IBOutlet weak private var titleLabel: UILabel!
    
    func configure(model: STAlbumFilesVC.HeaderModel?) {
        self.titleLabel.text = model?.text
    }

}
