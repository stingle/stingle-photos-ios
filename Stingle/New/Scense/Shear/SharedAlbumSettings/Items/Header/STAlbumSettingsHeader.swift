//
//  STSharedAlbumSettingsHeader.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/17/21.
//

import UIKit

class STAlbumSettingsHeader: UITableViewHeaderFooterView {

    @IBOutlet weak private var titleLabel: UILabel!
    
    override  func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = .clear
    }

    func configure(title: String?) {
        self.titleLabel.text = title
    }
    
}
