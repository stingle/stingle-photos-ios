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
    var delegate: STStorageCellDelegate? { get set }
    func confugure(model: IStorageCellModel?)
}

protocol STStorageCellDelegate: AnyObject {
    func storageCell(didSelectBuy cell: STStorageProductCell, model: STStorageProductCell.Model.Button)
}

class STStorageBaseCell<Model: IStorageCellModel>: UICollectionViewCell {
    
    private(set) var model: Model?
    
    weak var delegate: STStorageCellDelegate?

    func confugure(model: Model?) {
        self.model = model
    }

}

extension STStorageBaseCell: IStorageCell {
    
    func confugure(model: IStorageCellModel?) {
        self.confugure(model: (model as? Model))
    }
    
}
