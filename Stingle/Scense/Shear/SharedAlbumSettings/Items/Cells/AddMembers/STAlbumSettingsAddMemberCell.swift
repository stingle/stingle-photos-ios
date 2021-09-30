//
//  STAlbumSettingsAddMemberNameCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/17/21.
//

import UIKit

struct STAlbumSettingsAddMemberCellModel: ISharedAlbumSettingsItemModel {
    var itemType: STSharedAlbumSettingsVC.TableItem = .addMemberCell
    var id: Any? = nil
    let isEnabled: Bool
}

class STAlbumSettingsAddMemberCell: STSharedAlbumSettingsBaseCell<STAlbumSettingsAddMemberCellModel> {
    
    @IBOutlet weak private var addMemberButton: STButton!
    
    @IBAction private func didSelectAddMember(_ sender: Any) {
        guard let viewModel = self.model else {
            return
        }
        self.delegate?.sharedAlbumSettingsCell(cell: self, didSelectAddMember: viewModel)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addMemberButton.setTitle("add_member".localized, for: .normal)
    }
    
    override func configure(viewModel: STAlbumSettingsAddMemberCellModel?) {
        super.configure(viewModel: viewModel)
        self.addMemberButton.isEnabled = viewModel?.isEnabled ?? false
    }
    
}

