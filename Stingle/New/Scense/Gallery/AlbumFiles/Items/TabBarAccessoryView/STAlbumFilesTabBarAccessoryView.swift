//
//  STAlbumFilesTabBarAccessoryView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/1/21.
//

import UIKit

protocol STAlbumFilesTabBarAccessoryViewDelegate: AnyObject {
    
    func albumFilesTabBarAccessory(view: STAlbumFilesTabBarAccessoryView, didSelectShareButton sendner: UIButton)
    func albumFilesTabBarAccessory(view: STAlbumFilesTabBarAccessoryView, didSelectMoveButton sendner: UIButton)
    func albumFilesTabBarAccessory(view: STAlbumFilesTabBarAccessoryView, didSelectDownloadButton sendner: UIButton)
    func albumFilesTabBarAccessory(view: STAlbumFilesTabBarAccessoryView, didSelectTrashButton sendner: UIButton)
    
}

class STAlbumFilesTabBarAccessoryView: UIView {
    
    @IBOutlet weak private(set) var sharButton: STButton!
    @IBOutlet weak private(set) var copyButton: STButton!
    @IBOutlet weak private(set) var downloadButton: STButton!
    @IBOutlet weak private(set) var trashButton: STButton!
    @IBOutlet weak private(set) var titleLabel: UILabel!
    
    weak var delegate: STAlbumFilesTabBarAccessoryViewDelegate?
    
    
    @IBAction func didSelectShareButton(_ sender: UIButton) {
        self.delegate?.albumFilesTabBarAccessory(view: self, didSelectShareButton: sender)
    }
    
    @IBAction func didSelectCopyButton(_ sender: UIButton) {
        self.delegate?.albumFilesTabBarAccessory(view: self, didSelectMoveButton: sender)
    }
    
    @IBAction func didSelectDownloadButton(_ sender: UIButton) {
        self.delegate?.albumFilesTabBarAccessory(view: self, didSelectDownloadButton: sender)
    }
    
    @IBAction func didSelectTrashButton(_ sender: UIButton) {
        self.delegate?.albumFilesTabBarAccessory(view: self, didSelectTrashButton: sender)
    }
    
    func setEnabled(isEnabled: Bool) {
        self.sharButton.isEnabled = isEnabled
        self.copyButton.isEnabled = isEnabled
        self.downloadButton.isEnabled = isEnabled
        self.trashButton.isEnabled = isEnabled
    }
    
}

extension STAlbumFilesTabBarAccessoryView {
    
    class func loadNib() -> STAlbumFilesTabBarAccessoryView {
        let contentView = Bundle(for: self).loadNibNamed(String(describing: self), owner: self, options: nil)?.first as! STAlbumFilesTabBarAccessoryView
        return contentView
    }
    
}
