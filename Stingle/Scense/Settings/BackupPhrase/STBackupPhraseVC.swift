//
//  STBackupPhraseVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/6/21.
//

import UIKit

class STBackupPhraseVC: UIViewController {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var descriptionLabel: UILabel!
    @IBOutlet weak private var backupPhraseButton: STButton!
    
    private weak var backupPhraseView: STBackupPhraseView?
    private var viewModel = STBackupPhraseVM()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureLocalized()
    }
    
    //MARK: - Private methoth
    
    private func configureLocalized() {
        self.navigationItem.title = "menu_backup_phrase".localized
        self.titleLabel.text = "menu_backup_phrase".localized
        self.descriptionLabel.text = "backup_phrase_description".localized
        self.backupPhraseButton.setTitle("ok_get_backup_phrase".localized, for: .normal)
    }
    
    //MARK: - User action
    
    @IBAction private func didSelectBackupPhraseButton(_ sender: Any) {
        let title = "enter_app_password".localized
        self.showOkCancelTextAlert(title: title, message: nil) { textField in
            textField.placeholder = "password".localized
            textField.isSecureTextEntry = true
        } handler: { [weak self] text in
            self?.showBackupPhrase(password: text)
        } cancel: { }
    }
    
    @IBAction private func didSelectMenuBarItem(_ sender: Any) {
        if self.splitMenuViewController?.isMasterViewOpened ?? false {
            self.splitMenuViewController?.hide(master: true)
        } else {
            self.splitMenuViewController?.show(master: true)
        }
    }
    
    //MARK: - Privite methods
    
    private func showBackupPhrase(password: String?) {
        let view: UIView = self.navigationController?.view ?? self.view
        self.viewModel.getBackupPhrase(password: password) { [weak self] mnemonic in
            self?.backupPhraseView = STBackupPhraseView.show(in: view, text: mnemonic)
            self?.backupPhraseView?.delegate = self
        } failure: { [weak self] error in
            self?.showError(error: error)
        }
    }

}

extension STBackupPhraseVC: STBackupPhraseViewDelegate {
    
    func backupPhraseView(didSelectCancel backupPhraseView: STBackupPhraseView) {
        backupPhraseView.hide()
    }
    
    func backupPhraseView(didSelectCopy backupPhraseView: STBackupPhraseView, text: String?) {
        backupPhraseView.hide()
        self.viewModel.copy(backupPhrase: text)
    }
    
}
