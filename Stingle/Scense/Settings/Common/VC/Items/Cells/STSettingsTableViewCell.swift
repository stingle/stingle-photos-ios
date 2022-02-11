//
//  STSecurityVCTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

protocol ISettingsTableViewCellModel {
    var isEnabled: Bool { get set }
}

extension ISettingsTableViewCellModel {
    var isEnabled: Bool {
        return true
    }
}

protocol ISettingsTableViewCell: UITableViewCell {
    var delegate: STSettingsTableViewCellDelegate? { get set }
    var model: ISettingsTableViewCellModel? { get }
    func configure(model: ISettingsTableViewCellModel?)
}

protocol STSettingsTableViewCellDelegate: AnyObject {
    func settingsyCel(didSelectSwich cell: ISettingsTableViewCell, model: ISettingsTableViewCellModel, isOn: Bool)
    func settingsyCel(didSlide cell: ISettingsTableViewCell, model: ISettingsTableViewCellModel, value: Float)
}

class STSettingsTableViewCell<Model: ISettingsTableViewCellModel>: UITableViewCell, ISettingsTableViewCell {
   
    private(set) var model: ISettingsTableViewCellModel?
    weak var delegate: STSettingsTableViewCellDelegate?
    
    var cellModel: Model? {
        set {
            self.model = newValue
        } get {
            return self.model as? Model
        }
    }
    
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
