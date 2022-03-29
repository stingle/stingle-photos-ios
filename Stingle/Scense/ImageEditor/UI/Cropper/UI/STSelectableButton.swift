//
//  STSelectableButton.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 1/13/22.
//

import UIKit

class STSelectableButton: UIButton {

    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.tintColor = .appYellow
            } else {
                self.tintColor = UIColor(white: 0.725, alpha: 1)
            }
        }
    }

}
