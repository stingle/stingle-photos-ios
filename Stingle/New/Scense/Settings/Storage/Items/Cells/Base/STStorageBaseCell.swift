//
//  STStorageBaseCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import UIKit

protocol IStorageCell: UICollectionViewCell {
    func confugure(model: IStorageItemModel?)
}

class STStorageBaseCell<Model: IStorageItemModel>: UICollectionViewCell {
    
    private(set) var model: Model?
    
    func confugure(model: Model?) {
        self.model = model
    }

}

extension STStorageBaseCell: IStorageCell {
    
    func confugure(model: IStorageItemModel?) {
        self.confugure(model: (model as? Model))
    }
    
}
