//
//  STAutoImportDialogTableVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 1/4/22.
//

import UIKit

protocol STAutoImportDialogTableVCDelegate: AnyObject {
    func autoImportDialogTableVC(didChanged dialogTableVC: STAutoImportDialogTableVC, contentSize: CGSize)
    func autoImportDialogTableVC(didSelectSkip dialogTableVC: STAutoImportDialogTableVC)
    func autoImportDialogTableVC(didSelectOnImport dialogTableVC: STAutoImportDialogTableVC)
    func autoImportDialogTableVC(didSelectDeleteOreginalFilesSwich dialogTableVC: STAutoImportDialogTableVC, isOn: Bool)
    func autoImportDialogTableVC(didSelectImporsExistingFilesSwich dialogTableVC: STAutoImportDialogTableVC, isOn: Bool)
}

class STAutoImportDialogTableVC: UITableViewController {
    
    weak var delegate: STAutoImportDialogTableVCDelegate?
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var descriptionLabel: UILabel!
    @IBOutlet weak private var skipButton: STButton!
    @IBOutlet weak private var onImportButton: STButton!
    
    @IBOutlet weak private var deleteFilesLabel: UILabel!
    @IBOutlet weak private var deleteFilesSwich: UISwitch!
    @IBOutlet weak private var importExisItemsLabel: UILabel!
    @IBOutlet weak private var importExisItemsSwich: UISwitch!
    @IBOutlet weak private var importInfoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateLocalized()
    }
    
    //MARK: - User action
    
    @IBAction private func didSelectSkipButton(_ sender: Any) {
        self.delegate?.autoImportDialogTableVC(didSelectSkip: self)
    }
    
    @IBAction private func didSelectOnAutoImportButton(_ sender: Any) {
        self.delegate?.autoImportDialogTableVC(didSelectOnImport: self)
    }
    
    @IBAction func didSelectDeleteOreginalFilesSwich(_ sender: Any) {
        self.delegate?.autoImportDialogTableVC(didSelectDeleteOreginalFilesSwich: self, isOn: self.deleteFilesSwich.isOn)
    }
    
    @IBAction func didSelectImporsExistingFilesSwich(_ sender: Any) {
        self.delegate?.autoImportDialogTableVC(didSelectImporsExistingFilesSwich: self, isOn: self.importExisItemsSwich.isOn)
    }
    
    
    //MARK: - private methods
    
    private func updateLocalized() {
        self.titleLabel.text = "auto_import_settings".localized
        self.descriptionLabel.text = "auto_import_description".localized
        self.skipButton.setTitle("skip".localizedUpper, for: .normal)
        self.onImportButton.setTitle("true_on_auto_import".localizedUpper, for: .normal)
        self.deleteFilesLabel.text = "delete_original_files_after_import".localized
        self.importExisItemsLabel.text = "import_existing_items".localized
        self.importInfoLabel.text = "auto_import_info".localized
    }
    
}


extension STAutoImportDialogTableVC: STDynamicTableViewDelegate {
    
    func dynamicTableView(didChanged tableView: STDynamicTableView, contentSize: CGSize) {
        self.delegate?.autoImportDialogTableVC(didChanged: self, contentSize: contentSize)
    }
    
}


