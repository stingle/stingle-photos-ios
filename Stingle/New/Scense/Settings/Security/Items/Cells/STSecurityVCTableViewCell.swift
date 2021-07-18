//
//  STSecurityVCTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 7/14/21.
//

import UIKit

protocol ISecurityTableViewCellModel {
    var itemType: STSecurityVC.ItemType { get }
}

protocol ISecurityVCTableViewCell: UITableViewCell {
    var delegate: STSecurityVCTableViewCellDelegate? { get set }
    var model: ISecurityTableViewCellModel? { get }
    func configure(model: ISecurityTableViewCellModel)
}

protocol STSecurityVCTableViewCellDelegate: AnyObject {
    func securityCel(didSelectSwich cell: ISecurityVCTableViewCell, model: ISecurityTableViewCellModel, isOn: Bool)
}

class STSecurityVCTableViewCell<Model: ISecurityTableViewCellModel>: UITableViewCell, ISecurityVCTableViewCell {
    
    private(set) var model: ISecurityTableViewCellModel?
    weak var delegate: STSecurityVCTableViewCellDelegate?
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.alpha = self.isHighlighted ? 0.7 : 1
    }
    
    func configure(model: ISecurityTableViewCellModel) {
        guard let model = model as? Model else {
            fatalError("model not valid")
        }
        self.model = model
        self.configure(model: model)
    }
    
    func configure(model: Model) {
        fatalError("implement in child classes")
    }

}
