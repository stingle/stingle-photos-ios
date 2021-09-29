//
//  STSharedAlbumSettingsBaseCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/17/21.
//

import UIKit

protocol ISharedAlbumSettingsItemModel {
    var itemType: STSharedAlbumSettingsVC.TableItem { get }
    var id: Any? { get }
}

protocol ISharedAlbumSettingsCell: UITableViewCell {
    var delegate: STSharedAlbumSettingsCellDelegate? { get set }
    func configure(model: ISharedAlbumSettingsItemModel?)
}

protocol STSharedAlbumSettingsCellDelegate: AnyObject {
    func sharedAlbumSettingsCell(cell: ISharedAlbumSettingsCell, didSelectRemoveMember model: ISharedAlbumSettingsItemModel)
    func sharedAlbumSettingsCell(cell: ISharedAlbumSettingsCell, didSelectAddMember model: ISharedAlbumSettingsItemModel)
    func sharedAlbumSettingsCell(cell: ISharedAlbumSettingsCell, didSelectShare model: ISharedAlbumSettingsItemModel)
    func sharedAlbumSettingsCell(cell: ISharedAlbumSettingsCell, didSelectPermission  model: ISharedAlbumSettingsItemModel, isOn: Bool)
}

class STSharedAlbumSettingsBaseCell<Model: ISharedAlbumSettingsItemModel>: UITableViewCell, ISharedAlbumSettingsCell {
    
    private(set) var model: Model?
    
    weak var delegate: STSharedAlbumSettingsCellDelegate?
    
    func configure(model: ISharedAlbumSettingsItemModel?) {
        guard let model = model as? Model else {
            self.configure(viewModel: nil)
            return
        }
        self.configure(viewModel: model)
    }

    func configure(viewModel: Model?) {
        self.model = viewModel
    }

}
