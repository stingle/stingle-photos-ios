//
//  STSharedMembersTableViewCell.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/1/21.
//

import UIKit

class STSharedMembersTableViewCell: UITableViewCell {
   
    @IBOutlet weak private var checkMarkIcon: UIImageView!
    @IBOutlet weak private var emailLabel: UILabel!
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.alpha = self.isHighlighted ? 0.7 : 1
    }
    
    func confugure(email: String?, isSelected: Bool) {
        self.emailLabel.text = email
        self.confugure(isSelected: isSelected)
    }
    
    func confugure(isSelected: Bool) {
        let image = isSelected ? UIImage(named: "ic_mark") : UIImage(named: "ic_un_mark")
        self.checkMarkIcon.image = image
    }
    
}
