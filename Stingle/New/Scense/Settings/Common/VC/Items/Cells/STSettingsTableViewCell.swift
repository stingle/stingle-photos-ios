//
//  STSecurityVCTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

protocol ISettingsTableViewCellModel {
}

protocol ISettingsTableViewCell: UITableViewCell {
    var delegate: STSettingsTableViewCellDelegate? { get set }
    var model: ISettingsTableViewCellModel? { get }
    func configure(model: ISettingsTableViewCellModel?)
}

protocol STSettingsTableViewCellDelegate: AnyObject {
    func securityCel(didSelectSwich cell: ISettingsTableViewCell, model: ISettingsTableViewCellModel, isOn: Bool)
}

class STSettingsTableViewCell<Model: ISettingsTableViewCellModel>: UITableViewCell, ISettingsTableViewCell {
   
    private(set) var model: ISettingsTableViewCellModel?
    weak var delegate: STSettingsTableViewCellDelegate?
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.alpha = self.isHighlighted ? 0.7 : 1
    }
    
    func configure(model: ISettingsTableViewCellModel?) {
        self.configure(model: model as? Model)
    }
    
    func configure(model: Model?) {
        self.model = model
    }

}
