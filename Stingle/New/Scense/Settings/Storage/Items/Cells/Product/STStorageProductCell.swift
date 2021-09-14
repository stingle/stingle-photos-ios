//
//  STStorageProductCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/14/21.
//

import UIKit

extension STStorageProductCell {
    
    struct Model: IStorageCellModel {
        
        let identifier: String
        let quantity: String
        let type: String?
        let byText: String?
        let description: NSAttributedString?
        let isCurrent: Bool
        
    }
    
}

class STStorageProductCell:  STStorageBaseCell<STStorageProductCell.Model> {

    @IBOutlet weak private var quantityLabel: UILabel!
    @IBOutlet weak private var typeLabel: UILabel!
    @IBOutlet weak private var byButton: STButton!
    @IBOutlet weak private var descriptionLabel: UILabel!
    @IBOutlet weak private var bgView: STView!
    
    override func confugure(model: Model?) {
        super.confugure(model: model)
        
        self.quantityLabel.text = model?.quantity
        self.typeLabel.text = model?.type
        self.byButton.setTitle(model?.byText, for: .normal)
        self.descriptionLabel.attributedText = model?.description
        
        self.quantityLabel.isHidden = model?.quantity == nil
        self.typeLabel.isHidden = model?.type == nil
        self.byButton.isHidden = model?.byText == nil
        self.descriptionLabel.isHidden = model?.description == nil
        
        let isCurrent = model?.isCurrent ?? true
        
        if isCurrent {
            self.bgView.borderColor = .appPrimary
            self.byButton.backgroundColor = .lightGray
            self.byButton.isEnabled = false
        } else {
            self.bgView.borderColor = .lightGray
            self.byButton.backgroundColor = .appPrimary
            self.byButton.isEnabled = true
        }
        
    }

}
