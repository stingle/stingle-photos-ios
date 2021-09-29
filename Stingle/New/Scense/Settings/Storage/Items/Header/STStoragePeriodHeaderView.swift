//
//  STStoragePeriodHeaderView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/26/21.
//

import UIKit

protocol IStorageHeader: UICollectionReusableView {
    var delegate: STStorageHeaderViewDelegate? { get set}
    func confugure(model: IStorageItemModel?)
}

protocol STStorageHeaderViewDelegate: AnyObject {
    func storageHeaderView(didSelectSwich header: IStorageHeader, model: IStorageItemModel, isOn: Bool)
}

extension STStoragePeriodHeaderView {
    
    struct Model: IStorageItemModel {
        let description: String?
        let period: String?
        let swich: Bool
        let info: String?
        
        var identifier: String {
            var identifier = ""
            identifier = identifier + (self.description ?? "") + (self.period ?? "") + "\(self.swich)" +
            (self.info ?? "")
            return identifier
        }
        
    }
    
}

class STStoragePeriodHeaderView: UICollectionReusableView {
    
    @IBOutlet weak private var descriptionLabel: UILabel!
    @IBOutlet weak private var swich: UISwitch!
    @IBOutlet weak private var periodLabel: UILabel!
    @IBOutlet weak private var infoLabel: UILabel!
    
    private(set) var model: Model?
    
    weak var delegate: STStorageHeaderViewDelegate?
    
    func confugure(model: Model?) {
        self.model = model
        self.descriptionLabel.text = model?.description
        self.swich.isOn = model?.swich ?? false
        self.periodLabel.text = model?.period
        self.infoLabel.text = model?.info
        self.descriptionLabel.isHidden = model?.description == nil
        self.periodLabel.isHidden = model?.period == nil
        self.infoLabel.superview?.isHidden = model?.info == nil
    }
    
    //MARK: - User action
    
    @IBAction private func didSelectSwich(_ sender: Any) {
        guard let model = self.model else {
            return
        }
        self.delegate?.storageHeaderView(didSelectSwich: self, model: model, isOn: self.swich.isOn)
    }
    
}

extension STStoragePeriodHeaderView: IStorageHeader {
    
    func confugure(model: IStorageItemModel?) {
        self.confugure(model: model as? Model)
    }
    
}
