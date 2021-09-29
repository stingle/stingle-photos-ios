//
//  STUploadsTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/24/21.
//

import UIKit

class STUploadsTableViewCell: UITableViewCell {

    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak private var fileImageView: STImageView!
    private(set) var model: STUploadsVC.CellModel?
    
    func configure(model: STUploadsVC.CellModel?) {
        self.model = model
        self.nameLabel.text = model?.name
        self.fileImageView?.setImage(source: model?.image)
        self.progressView.progress = model?.progress ?? 0
    }
    
    func updateProgress(progress: Float) {
        self.progressView.progress = progress
    }
    
}
