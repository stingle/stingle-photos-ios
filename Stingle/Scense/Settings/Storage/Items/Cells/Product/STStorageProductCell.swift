//
//  STStorageProductCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/14/21.
//

import UIKit

extension STStorageProductCell {
    
    struct Model: IStorageItemModel {
        let identifier: String
        let quantity: String?
        let price: String?
        let period: String?
        let prodictID: String?
        let isSelected: Bool
    }
    
}

class STStorageProductCell:  STStorageBaseCell<STStorageProductCell.Model> {

    @IBOutlet weak private var quantityLabel: UILabel!
    @IBOutlet weak private var priceLabel: UILabel!
    @IBOutlet weak private var periodLabel: UILabel!
    @IBOutlet weak private var checkImageView: UIImageView!
    @IBOutlet weak private var bgView: UIView!
    
    override var isHighlighted: Bool {
        didSet {
            self.bgView.alpha = self.isHighlighted ? 0.7 : 1
        }
    }
    
    override func confugure(model: Model?) {
        super.confugure(model: model)
        
        self.quantityLabel.text = model?.quantity
        self.priceLabel.text = model?.price
        self.periodLabel.text = model?.period
        
        let isSelected = model?.isSelected ?? false
        
        let imageName = isSelected ? "ic_rounded_check_mark_check" : "ic_rounded_check_mark"
        let checkTintColor: UIColor = isSelected ? .appPrimary : .darkGray
        let bgColor: UIColor = isSelected ? .lightGray.withAlphaComponent(0.3) : .clear
        
        self.checkImageView.image = UIImage(named: imageName)
        self.checkImageView.tintColor = checkTintColor
        self.bgView.backgroundColor = bgColor
    }
    

}
