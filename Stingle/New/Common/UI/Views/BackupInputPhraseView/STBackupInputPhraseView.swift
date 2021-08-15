//
//  STBackupInputPhraseView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/15/21.
//

import UIKit

protocol STBackupInputPhraseViewDelegate: AnyObject {
    func backupPhraseView(didSelectCancel backupPhraseView: STBackupInputPhraseView)
    func backupPhraseView(didSelectOk backupPhraseView: STBackupInputPhraseView, text: String?)
}

class STBackupInputPhraseView: UIView {

    @IBOutlet weak private var okButton: STButton!
    @IBOutlet weak private var cancelButton: STButton!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subTitleLabel: UILabel!
    @IBOutlet weak private var textView: ATTextView!
    @IBOutlet weak private var bottomLayoutConstraint: NSLayoutConstraint!
    
    weak var delegate: STBackupInputPhraseViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.okButton.setTitle("ok".localized, for: .normal)
        self.cancelButton.setTitle("cancel".localized, for: .normal)
        self.titleLabel.text = "backup_phrase_input_title".localized
        self.subTitleLabel.text = "backup_phrase_input_sup_title".localized
        self.textView.placeholder = "backup_phrase_input_placeholder".localized
        self.addNotifications()
    }
    
    @IBAction private func didSelectCancel(_ sender: Any) {
        self.delegate?.backupPhraseView(didSelectCancel: self)
    }
    
    @IBAction private func didSelectOk(_ sender: Any) {
        self.delegate?.backupPhraseView(didSelectOk: self, text: self.textView.text)
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = .zero
        } completion: { [weak self] _ in
            self?.removeFromSuperview()
        }
    }
    
    //MARK: - Private
    
    private func addNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrameNotification(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func keyboardWillChangeFrameNotification(_ notification: Notification) {
        let userInfo = notification.userInfo
        guard let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        self.bottomLayoutConstraint.constant = keyboardFrame.height
        self.layoutIfNeeded()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}


extension STBackupInputPhraseView {
    
    class func show(in view: UIView) -> STBackupInputPhraseView {
        let contentView = Bundle(for: self).loadNibNamed(String(describing: self), owner: self, options: nil)?.first as! STBackupInputPhraseView
        contentView.alpha = .zero
        view.addSubviewFullContent(view: contentView)
        UIView.animate(withDuration: 0.3) {
            contentView.alpha = 1
        } completion: { _ in
            let _ = contentView.textView.becomeFirstResponder()
        }
        return contentView
    }
    
}
