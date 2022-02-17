//
//  STResizeView.swift
//  Stingle
//
//  Created by Shahen Antonyan on 2/15/22.
//

import UIKit

protocol STResizeViewDelegate: AnyObject {
    func resizeView(view: STResizeView, didSelectSize size: CGSize)
    func resizeView(didSelectCancel view: STResizeView)
}

class STResizeView: UIView {

    @IBOutlet weak var resizeButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var widthLabel: UILabel!
    @IBOutlet weak var widthTextField: UITextField!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var heightTextField: UITextField!

    weak var delegate: STResizeViewDelegate?

    var imageSize: CGSize? {
        didSet {
            self.widthTextField?.text = self.imageSize == nil ? nil : "\(Int(self.imageSize!.width))"
            self.heightTextField?.text = self.imageSize == nil ? nil : "\(Int(self.imageSize!.height))"
            self.widthTextField.isEnabled = self.imageSize != nil
            self.heightTextField.isEnabled = self.imageSize != nil
            self.resizeButton.isEnabled = self.imageSize != nil
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.resizeButton.setTitle("editor_resize".localized, for: .normal)
        self.cancelButton.setTitle("cancel".localized, for: .normal)
        self.widthTextField.placeholder = "editor_width".localized.lowercased()
        self.heightTextField.placeholder = "editor_height".localized.lowercased()
        self.widthTextField?.text = self.imageSize == nil ? nil : "\(Int(self.imageSize!.width))"
        self.heightTextField?.text = self.imageSize == nil ? nil : "\(Int(self.imageSize!.height))"
    }

    @IBAction func widthTextFieldValueChanged(_ sender: Any) {
        let value = (self.widthTextField.text?.isEmpty ?? true) ? "0" : self.widthTextField.text!
        guard let intValue = Int(value) else {
            return
        }
        guard let imageSize = self.imageSize else {
            return
        }
        let height = Int(imageSize.height / imageSize.width * CGFloat(intValue))
        self.heightTextField.text = "\(height)"
        self.resizeButton.isEnabled = height != 0 && intValue != 0
    }

    @IBAction func heightTextFieldValueChanged(_ sender: Any) {
        let value = (self.heightTextField.text?.isEmpty ?? true) ? "0" : self.heightTextField.text!
        guard let intValue = Int(value) else {
            return
        }
        guard let imageSize = self.imageSize else {
            return
        }
        let width = Int(imageSize.width / imageSize.height * CGFloat(intValue))
        self.widthTextField.text = "\(width)"
        self.resizeButton.isEnabled = width != 0 && intValue != 0
    }

    @IBAction func resizeButtonAction(_ sender: Any) {
        guard let value = self.widthTextField.text, let widthIntValue = Int(value) else {
            return
        }
        guard let value = self.heightTextField.text, let heightIntValue = Int(value) else {
            return
        }
        guard widthIntValue > 0 && heightIntValue > 0 else {
            return
        }
        self.widthTextField.resignFirstResponder()
        self.heightTextField.resignFirstResponder()
        self.delegate?.resizeView(view: self, didSelectSize: CGSize(width: widthIntValue, height: heightIntValue))
    }

    @IBAction func cancelButtonAction(_ sender: Any) {
        self.widthTextField.resignFirstResponder()
        self.heightTextField.resignFirstResponder()
        self.delegate?.resizeView(didSelectCancel: self)
    }

}
