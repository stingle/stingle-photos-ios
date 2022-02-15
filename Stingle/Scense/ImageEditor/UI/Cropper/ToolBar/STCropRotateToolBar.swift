//
//  STCropRotateToolBar.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 1/13/22.
//

import UIKit

protocol STCropRotateToolBarDelegate: AnyObject {
    func flipButtonDidPress()
    func rotateButtonDidPress()
    func resizeButtonDidPress()
    func aspectRatioButtonDidPress(isSelected: Bool)
}

class STCropRotateToolBar: UIView {

    weak var delegate: STCropRotateToolBarDelegate?

    @IBAction func flipButtonAction(_ sender: Any) {
        self.delegate?.flipButtonDidPress()
    }

    @IBAction func rotateButtonAction(_ sender: Any) {
        self.delegate?.rotateButtonDidPress()
    }

    @IBAction func aspectRatioButtonAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.delegate?.aspectRatioButtonDidPress(isSelected: sender.isSelected)
    }

    @IBAction func resizerButtonAction(_ sender: UIButton) {
        self.delegate?.resizeButtonDidPress()
    }
    
}
