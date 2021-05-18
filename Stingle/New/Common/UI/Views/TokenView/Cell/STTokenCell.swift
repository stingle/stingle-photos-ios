//
//  STTokenCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/2/21.
//

import UIKit

protocol STTokenCellDelegate: AnyObject {
    func tokenCell(didSelectClear tokenCell: STTokenCell)
}

class STTokenCell: UICollectionViewCell {
    
    weak var delegate: STTokenCellDelegate?
    @IBOutlet weak private var titleLabel: UILabel!
    
    @IBAction private func didSelectClearButton(_ sender: Any) {
        self.delegate?.tokenCell(didSelectClear: self)
    }
    
    func configure(text: String?) {
        self.titleLabel.text = text
    }
    
}
