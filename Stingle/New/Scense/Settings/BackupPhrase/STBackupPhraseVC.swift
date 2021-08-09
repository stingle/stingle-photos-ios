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
        
        
    }
    
    @IBAction private func didSelectMenuBarItem(_ sender: Any) {
        if self.splitMenuViewController?.isMasterViewOpened ?? false {
            self.splitMenuViewController?.hide(master: true)
        } else {
            self.splitMenuViewController?.show(master: true)
        }
    }

}
