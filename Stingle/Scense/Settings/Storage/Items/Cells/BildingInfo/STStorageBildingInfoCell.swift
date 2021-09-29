//
//  STStorageBildingInfoCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/14/21.
//

import UIKit

extension STStorageBildingInfoCell {
    
    struct Model: IStorageItemModel {
        let title: String
        let used: String
        let usedProgress: Float
        
        var identifier: String {
            return self.used + self.title
        }
    }
    
}

class STStorageBildingInfoCell: STStorageBaseCell<STStorageBildingInfoCell.Model> {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
    @IBOutlet weak private var progressView: UIProgressView!
    
    override func confugure(model: Model?) {
        super.confugure(model: model)
        self.titleLabel.text = model?.title
        self.subTitleLabel.text = model?.used
        self.progressView.progress = model?.usedProgress ?? .zero
    }

}
