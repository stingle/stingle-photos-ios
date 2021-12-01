//
//  STAboutBaseTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/28/21.
//

import UIKit

protocol IAboutBaseTableViewCell: UITableViewCell {
    var item: IAboutVCCellItem? { get }
    func configure(item: IAboutVCCellItem?)
}

class STAboutBaseTableViewCell<Model: IAboutVCCellItem>: UITableViewCell {

    private(set) var model: Model?
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.alpha = self.isHighlighted ? 0.7 : 1
    }
    
    func configure(model: Model?) {
        self.model = model
    }
    
}

extension STAboutBaseTableViewCell: IAboutBaseTableViewCell {
    
    var item: IAboutVCCellItem? {
        return self.model
    }
    
    func configure(item: IAboutVCCellItem?) {
        self.configure(model: item as? Model)
    }
    
}
