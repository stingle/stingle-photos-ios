//
//  STAlbumSettingsMemberCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/17/21.
//

import UIKit

struct STAlbumSettingsMemberCellModel: ISharedAlbumSettingsItemModel {
    var itemType: STSharedAlbumSettingsVC.TableItem = .memberCell
    var id: Any?
    let isEnabled: Bool
    let email: String?
}

class STAlbumSettingsMemberCell: STSharedAlbumSettingsBaseCell<STAlbumSettingsMemberCellModel> {

    @IBOutlet weak private var removeButton: UIButton!
    @IBOutlet weak private var emailLabel: UILabel!
    
    @IBAction private func didSelectRemoveButton(_ sender: Any) {
        guard let viewModel = self.model else {
            return
        }
        self.delegate?.sharedAlbumSettingsCell(cell: self, didSelectRemoveMember: viewModel)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.removeButton.setTitle("remove", for: .normal)
    }
    
    override func configure(viewModel: STAlbumSettingsMemberCellModel?) {
        super.configure(viewModel: viewModel)
        self.removeButton.isHidden = !(viewModel?.isEnabled ?? false)
        self.emailLabel.text = viewModel?.email
    }
    
}
