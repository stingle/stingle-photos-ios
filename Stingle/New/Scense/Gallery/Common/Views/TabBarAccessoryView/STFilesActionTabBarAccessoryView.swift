//
//  STAlbumFilesTabBarAccessoryView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/1/21.
//

import UIKit

protocol STFilesActionTabBarAccessoryViewDelegate: AnyObject {
    
    func filesActionTabBarAccessory(view: STFilesActionTabBarAccessoryView, didSelectShareButton sendner: UIButton)
    func filesActionTabBarAccessory(view: STFilesActionTabBarAccessoryView, didSelectMoveButton sendner: UIButton)
    func filesActionTabBarAccessory(view: STFilesActionTabBarAccessoryView, didSelectSaveToDeviceButton sendner: UIButton)
    func filesActionTabBarAccessory(view: STFilesActionTabBarAccessoryView, didSelectTrashButton sendner: UIButton)
    
}

class STFilesActionTabBarAccessoryView: UIView {
    
    @IBOutlet weak private(set) var sharButton: STButton!
    @IBOutlet weak private(set) var moveButton: STButton!
    @IBOutlet weak private(set) var downloadButton: STButton!
    @IBOutlet weak private(set) var trashButton: STButton!
    @IBOutlet weak private(set) var titleLabel: UILabel!
    
    weak var delegate: STFilesActionTabBarAccessoryViewDelegate?
    
    
    @IBAction func didSelectShareButton(_ sender: UIButton) {
        self.delegate?.filesActionTabBarAccessory(view: self, didSelectShareButton: sender)
    }
    
    @IBAction func didSelectMoveButton(_ sender: UIButton) {
        self.delegate?.filesActionTabBarAccessory(view: self, didSelectMoveButton: sender)
    }
    
    @IBAction func didSelectDownloadButton(_ sender: UIButton) {
        self.delegate?.filesActionTabBarAccessory(view: self, didSelectSaveToDeviceButton: sender)
    }
    
    @IBAction func didSelectTrashButton(_ sender: UIButton) {
        self.delegate?.filesActionTabBarAccessory(view: self, didSelectTrashButton: sender)
    }
    
    func setEnabled(isEnabled: Bool) {
        self.sharButton.isEnabled = isEnabled
        self.moveButton.isEnabled = isEnabled
        self.downloadButton.isEnabled = isEnabled
        self.trashButton.isEnabled = isEnabled
    }
    
}

extension STFilesActionTabBarAccessoryView {
    
    class func loadNib() -> STFilesActionTabBarAccessoryView {
        let contentView = Bundle(for: self).loadNibNamed(String(describing: self), owner: self, options: nil)?.first as! STFilesActionTabBarAccessoryView
        return contentView
    }
    
}
