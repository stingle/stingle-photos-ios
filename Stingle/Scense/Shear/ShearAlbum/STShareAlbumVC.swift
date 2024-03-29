//
//  STShareAlbumVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/3/21.
//

import UIKit
import StingleRoot

protocol STShareAlbumVCDelegate: AnyObject {
    func shareAlbumVC(didShare shareAlbumVC: STShareAlbumVC)
}

class STShareAlbumVC: UITableViewController {
    
    @IBOutlet weak private var shareButtonItem: UIBarButtonItem!
    
    @IBOutlet weak private var addPhotoSwicher: UISwitch!
    @IBOutlet weak private var sharingSwicher: UISwitch!
    @IBOutlet weak private var copyingSwicher: UISwitch!
    
    @IBOutlet weak private var shareAlbumNameLabel: UILabel!
    @IBOutlet weak private var shareAlbumNameTextField: STTextField!
    
    @IBOutlet weak private var permitionsLabel: UILabel!
    
    @IBOutlet weak private var addNewPhotosTitleLabel: UILabel!
    @IBOutlet weak private var addNewPhotosDescriptionLabel: UILabel!
    
    @IBOutlet weak private var sharingTitleLabel: UILabel!
    @IBOutlet weak private var sharingDescriptionLabel: UILabel!
    
    @IBOutlet weak private var copyingTitleLabel: UILabel!
    @IBOutlet weak private var copyingDescriptionLabel: UILabel!
    
    weak var delegate: STShareAlbumVCDelegate?
    
    private let viewModel = STShareAlbumVM()
    
    var shareAlbumData: ShareAlbumData!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configurLocalizes()
        self.configurTextField()
    }
    
    private func configurLocalizes() {
        self.navigationItem.title = "sharing".localized
        self.shareButtonItem.title = "share".localized
        self.shareAlbumNameTextField.placeholder = "shared_album".localized
        self.permitionsLabel.text = "permissions".localized
        self.addNewPhotosTitleLabel.text = "permition_add_new_photos".localized
        self.addNewPhotosDescriptionLabel.text = "permition_add_new_photos_description".localized
        self.sharingTitleLabel.text = "permition_sharing".localized
        self.sharingDescriptionLabel.text = "permition_sharing_description".localized
        self.copyingTitleLabel.text = "permition_copying".localized
        self.copyingDescriptionLabel.text = "permition_copying_description".localized        
    }
    
    private func configurTextField() {
        switch self.shareAlbumData.shareType {
        case .album(let album):
            self.shareAlbumNameTextField.text = album.albumMetadata?.name
            self.shareAlbumNameTextField.isEnabled = false
            self.shareAlbumNameLabel.text = album.albumMetadata?.name
        case .files:
            self.shareAlbumNameTextField.text = STDateManager.shared.dateToString(date: Date(), withFormate: .mmm_dd_yyyy)
            self.shareAlbumNameTextField.isEnabled = true
            self.shareAlbumNameLabel.text = nil
        case .albumFiles:
            self.shareAlbumNameTextField.isEnabled = true
            self.shareAlbumNameTextField.text = STDateManager.shared.dateToString(date: Date(), withFormate: .mmm_dd_yyyy)
            self.shareAlbumNameLabel.text = nil
        }
    }
    
    private func shareAlbum(album: STLibrary.Album) {
        let permitions = (self.addPhotoSwicher.isOn, self.sharingSwicher.isOn, self.copyingSwicher.isOn)
        let loadingView: UIView = (self.navigationController?.view ?? self.view)
        STLoadingView.show(in: loadingView)
        self.viewModel.shareAlbum(album: album, contact: self.shareAlbumData.contact, permitions: permitions) { [weak self] error in
            guard let weakSelf = self else {
                return
            }
            STLoadingView.hide(in: loadingView)
            if let error = error {
                weakSelf.showError(error: error)
            } else {
                weakSelf.delegate?.shareAlbumVC(didShare: weakSelf)
                weakSelf.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func shareAlbumFiles(album: STLibrary.Album, files: [STLibrary.AlbumFile]) {
        let loadingView: UIView = (self.navigationController?.view ?? self.view)
        STLoadingView.show(in: loadingView)
        let name = self.shareAlbumNameTextField.text ?? ""
        let permitions = (self.addPhotoSwicher.isOn, self.sharingSwicher.isOn, self.copyingSwicher.isOn)
        self.viewModel.shareAlbumFiles(name: name, album: album, files: files, contact: self.shareAlbumData.contact, permitions: permitions) { [weak self] error in
            guard let weakSelf = self else {
                return
            }
            STLoadingView.hide(in: loadingView)
            if let error = error {
                weakSelf.showError(error: error)
            } else {
                weakSelf.delegate?.shareAlbumVC(didShare: weakSelf)
                weakSelf.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func shareFiles(files: [STLibrary.GaleryFile]) {
        let loadingView: UIView = (self.navigationController?.view ?? self.view)
        STLoadingView.show(in: loadingView)
        let name = self.shareAlbumNameTextField.text ?? ""
        let permitions = (self.addPhotoSwicher.isOn, self.sharingSwicher.isOn, self.copyingSwicher.isOn)
        
        self.viewModel.shareFiles(name: name, files: files, contact:  self.shareAlbumData.contact, permitions: permitions) { [weak self] error in
            
            guard let weakSelf = self else {
                return
            }
            STLoadingView.hide(in: loadingView)
            if let error = error {
                weakSelf.showError(error: error)
            } else {
                weakSelf.delegate?.shareAlbumVC(didShare: weakSelf)
                weakSelf.dismiss(animated: true, completion: nil)
            }
        }
                
    }
    
    //MARK: - UserAction
    
    @IBAction private func didSelectShareButton(_ sender: Any) {
        _ = self.shareAlbumNameTextField.resignFirstResponder()
        switch self.shareAlbumData.shareType {
        case .album(let album):
            self.shareAlbum(album: album)
        case .files(let files):
            self.shareFiles(files: files)
        case .albumFiles(let album, let files):
            self.shareAlbumFiles(album: album, files: files)
        }
    }
    
}

extension STShareAlbumVC {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

extension STShareAlbumVC {
    
    struct ShareAlbumData {
        let shareType: STSharedMembersVC.ShearedType
        let contact: [STContact]
    }
    
}
