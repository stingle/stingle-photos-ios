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
        let showsImage = model?.showsImage ?? true
        // The thumbnail lives inside a grey `STPlaceholder` container view; hide the whole
        // container (not just the image view) for status rows that have no thumbnail.
        self.fileImageView?.superview?.isHidden = !showsImage
        self.fileImageView?.setImage(source: showsImage ? model?.image : nil)
        self.progressView.progress = model?.progress ?? 0
    }
    
    func updateProgress(progress: Float) {
        self.progressView.progress = progress
    }
    
}
