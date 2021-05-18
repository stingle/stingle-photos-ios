//
//  STSharedAlbumSettingsPermissionCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/17/21.
//

import UIKit

struct STAlbumSettingsPermissionCellModel: ISharedAlbumSettingsItemModel {
    var itemType: STSharedAlbumSettingsVC.TableItem = .permissionCell
    var id: Any? = nil
    var permission: Bool
    let isEnabled: Bool
    let title: String?
    let subTitle: String?
}

class STAlbumSettingsPermissionCell: STSharedAlbumSettingsBaseCell<STAlbumSettingsPermissionCellModel> {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
    @IBOutlet weak private var `switch`: UISwitch!
    
    @IBAction private func didSelectSwich(_ sender: Any) {
        guard let viewModel = self.model else {
            return
        }
        self.delegate?.sharedAlbumSettingsCell(cell: self, didSelectPermission: viewModel, isOn: self.switch.isOn)
    }

    override func configure(viewModel: STAlbumSettingsPermissionCellModel?) {
        super.configure(viewModel: viewModel)
        self.switch.isOn = viewModel?.permission ?? false
        self.switch.isEnabled = viewModel?.isEnabled ?? false
        self.titleLabel.text = viewModel?.title
        self.subTitleLabel.text = viewModel?.subTitle
    }
    
}
