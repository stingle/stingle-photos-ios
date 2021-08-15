//
//  STBackupPhraseView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/14/21.
//

import UIKit

protocol STBackupPhraseViewDelegate: AnyObject {
    func backupPhraseView(didSelectCancel backupPhraseView: STBackupPhraseView)
    func backupPhraseView(didSelectCopy backupPhraseView: STBackupPhraseView, text: String?)
}

class STBackupPhraseView: UIView {
   
    @IBOutlet weak private var copyTextButton: STButton!
    @IBOutlet weak private var cancelButton: STButton!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var textLabel: UILabel!
    
    weak var delegate: STBackupPhraseViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.copyTextButton.setTitle("copy".localized, for: .normal)
        self.cancelButton.setTitle("cancel".localized, for: .normal)
        self.titleLabel.text = "your_backup_phrase".localized
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = .zero
        } completion: { [weak self] _ in
            self?.removeFromSuperview()
        }
    }
    
    //MARK - User action
    
    
    @IBAction private func didSelectBackround(_ sender: Any) {
        self.delegate?.backupPhraseView(didSelectCancel: self)
    }
    
    @IBAction private func didSelectCancel(_ sender: Any) {
        self.delegate?.backupPhraseView(didSelectCancel: self)
    }
    
    @IBAction private func didSelectCopy(_ sender: Any) {
        self.delegate?.backupPhraseView(didSelectCopy: self, text: self.textLabel.text)
    }
    
}

extension STBackupPhraseView {
    
    class func show(in view: UIView, text: String?) -> STBackupPhraseView {
        
        let contentView = Bundle(for: self).loadNibNamed(String(describing: self), owner: self, options: nil)?.first as! STBackupPhraseView
        contentView.textLabel.text = text
        contentView.alpha = .zero
        
        view.addSubviewFullContent(view: contentView)
        
        UIView.animate(withDuration: 0.3) {
            contentView.alpha = 1
        }
        
        return contentView
    }
    
}
