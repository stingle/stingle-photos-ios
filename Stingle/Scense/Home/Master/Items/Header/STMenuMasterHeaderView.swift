//
//  STmenuMasterHeaderView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/5/21.
//

import UIKit

class STMenuMasterHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak private var appNameLabel: UILabel!
    @IBOutlet weak private var userEmailLabel: UILabel!
    @IBOutlet weak private var spaceUsegLabel: UILabel!
    @IBOutlet weak private var progressView: UIProgressView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = .clear
    }

    func configure(model: STMenuMasterVC.Menu.Header?) {
        self.appNameLabel.text = model?.appName
        self.userEmailLabel.text = model?.userEmail
        self.spaceUsegLabel.text = model?.used
        self.progressView.progress = model?.usedProgress ?? 0
    }
    
}
