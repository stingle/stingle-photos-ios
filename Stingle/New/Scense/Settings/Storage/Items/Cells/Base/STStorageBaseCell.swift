//
//  STStorageBaseCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 9/11/21.
//

import UIKit

protocol IStorageCellModel {
    var identifier: String { get }
}

protocol IStorageCell: UICollectionViewCell {
    
    func confugure(model: IStorageCellModel?)
    
}

class STStorageBaseCell<Model: IStorageCellModel>: UICollectionViewCell {
    
    private(set) var model: Model?

    func confugure(model: Model?) {
        self.model = model
    }

}

extension STStorageBaseCell: IStorageCell {
    
    func confugure(model: IStorageCellModel?) {
        self.confugure(model: (model as? Model))
    }
    
}
