//
//  STStorageProductCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/14/21.
//

import UIKit

extension STStorageProductCell {
    
    struct Model: IStorageCellModel {
        
        struct Button {
            let text: String
            let isEnabled: Bool
            let identifier: String
        }
        
        let identifier: String
        let quantity: String
        let type: String?
        let buyButtonFirst: Button?
        let description: String?
        let buyButtonSecondary: Button?
        let isHighlighted: Bool
    }
    
}

class STStorageProductCell:  STStorageBaseCell<STStorageProductCell.Model> {

    @IBOutlet weak private var quantityLabel: UILabel!
    @IBOutlet weak private var typeLabel: UILabel!
    @IBOutlet weak private var buyFirstButton: STButton!
    @IBOutlet weak private var descriptionLabel: UILabel!
    @IBOutlet weak private var bgView: STView!
    @IBOutlet weak private var buyButtonSecondaryButton: STButton!
    
    override func confugure(model: Model?) {
        super.confugure(model: model)
        self.quantityLabel.text = model?.quantity
        self.typeLabel.text = model?.type
        self.descriptionLabel.text = model?.description
        self.configureButton(button: self.buyFirstButton, info: model?.buyButtonFirst)
        self.configureButton(button: self.buyButtonSecondaryButton, info: model?.buyButtonSecondary)
        let isHighlighted = model?.isHighlighted ?? false
        self.bgView.borderColor = isHighlighted ? .appPrimary : .lightGray
        
        self.quantityLabel.isHidden = model?.quantity == nil
        self.typeLabel.isHidden = model?.type == nil
        self.buyFirstButton.isHidden = model?.buyButtonFirst == nil
        self.descriptionLabel.isHidden = model?.description == nil
        self.buyButtonSecondaryButton.isHidden = model?.buyButtonSecondary == nil
        
    }

    @IBAction private func didSelectBuyFirst(_ sender: Any) {
        guard let model = self.model?.buyButtonFirst else {
            return
        }
        self.delegate?.storageCell(didSelectBuy: self, model: model)
    }
    
    @IBAction private func didSelectBuySecondary(_ sender: Any) {
        guard let model = self.model?.buyButtonSecondary else {
            return
        }
        self.delegate?.storageCell(didSelectBuy: self, model: model)
    }
    
    //MARK: - Private methods
    
    private func configureButton(button: STButton, info: Model.Button?)  {
        button.setTitle(info?.text, for: .normal)
        let isEnabled = info?.isEnabled ?? false
        button.isEnabled = isEnabled
        button.backgroundColor = isEnabled ? .appPrimary : .lightGray
    }
    
}
