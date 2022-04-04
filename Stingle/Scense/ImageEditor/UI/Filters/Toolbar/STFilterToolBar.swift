//
//  STFilterToolBar.swift
//  Stingle
//
//  Created by Shahen Antonyan on 2/15/22.
//

import UIKit

protocol STFilterToolBarDelegate: AnyObject {
    func resizeButtonDidPress()
}

class STFilterToolBar: UIView {

    @IBOutlet weak var titleLabel: UILabel!

    weak var delegate: STFilterToolBarDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel.text = "editor_adjust".localized.uppercased()
    }

    @IBAction func resizerButtonAction(_ sender: UIButton) {
        self.delegate?.resizeButtonDidPress()
    }

}
