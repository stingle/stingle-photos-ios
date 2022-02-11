//
//  STAlbumFilesTabBarAccessoryView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/1/21.
//

import UIKit

protocol STFilesActionTabBarAccessoryViewDataSource: AnyObject {
    func accessoryView(actions accessoryView: STFilesActionTabBarAccessoryView) -> [STFilesActionTabBarAccessoryView.ActionItem]
}

extension STFilesActionTabBarAccessoryView {
    
    struct ActionItem {
        
        let title: String?
        let image: UIImage?
        let tintColor: UIColor
        let handler: ((Self, UIBarButtonItem) -> Void)
        let identifier: StringPointer?
        
        static func share(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(named: "ic_shared_album_min")
            let result = ActionItem(title: nil, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }
        
        static func move(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(named: "ic_move")
            let result = ActionItem(title: nil, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }
        
        static func saveToDevice(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(named: "ic_save_device")
            let result = ActionItem(title: nil, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }
        
        static func trash(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(named: "ic_trash")
            let result = ActionItem(title: nil, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }
        
        static func recover(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(named: "ic_ recover")
            let result = ActionItem(title: nil, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }
        
        static func deleteAll(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let result = ActionItem(title: "delete_all".localized, image: nil, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }
        
        static func recoverAll(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let result = ActionItem(title: "recover_all".localized, image: nil, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }

        static func edit(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(named: "ic_edit")
            let result = ActionItem(title: nil, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }
        
    }
    
    private class ButtonItem: UIBarButtonItem {
        var actionItem: ActionItem?
    }
    
}

class STFilesActionTabBarAccessoryView: UIView {
    
    @IBOutlet weak private(set) var toolBar: UIToolbar!
    weak var dataSource: STFilesActionTabBarAccessoryViewDataSource?
    
    var title: String? {
        didSet {
            self.titleLabel?.text = self.title
            if self.title == nil {
                self.removeTtileItem(animated: true)
            } else {
                self.addTtileItem(animated: true)
            }
            self.titleLabel?.sizeToFit()
        }
    }
    
    var titleColor: UIColor = .appText {
        didSet {
            self.titleLabel?.textColor = self.titleColor
        }
    }
    
    private weak var titleLabel: UILabel?
    
    
    func setEnabled(isEnabled: Bool) {
        self.toolBar.items?.forEach({ item in
            (item as? ButtonItem)?.isEnabled = isEnabled
        })
    }
    
    func reloadData() {
        guard let dataSource = self.dataSource else {
            self.toolBar.setItems(nil, animated: false)
            return
        }
        let actions = dataSource.accessoryView(actions: self)
        
        var items = [UIBarButtonItem]()
        
        actions.forEach { action in
            let item = ButtonItem(image: action.image, style: .done, target: self, action: #selector(didSelectItem(item:)))
            item.actionItem = action
            item.title = action.title
            item.tintColor = action.tintColor
            items.append(item)
            let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            space.width = 20
            items.append(space)
        }
       
        if let item = self.getTtileItem() {
            items.append(item)
        }
        self.toolBar.setItems(items, animated: false)
    }
    
    func barButtonItem(for identifier: StringPointer?) -> UIBarButtonItem? {
        self.toolBar.items?.first(where: { ($0 as? ButtonItem)?.actionItem?.identifier?.stringValue == identifier?.stringValue })
    }
    
    //MARK: - User action
    
    @objc private func didSelectItem(item: ButtonItem) {
        if let actionItem = item.actionItem {
            actionItem.handler(actionItem, item)
        }
    }
    
    //MARK: - Private methods
    
    private func createTtileLabel() -> UILabel? {
        guard let title = self.title else {
            return nil
        }
        let label = UILabel()
        label.text = title
        label.font = UIFont.medium(light: 15)
        label.textColor = self.titleColor
        return label
    }
    
    private func getTtileItem() -> UIBarButtonItem? {
        guard let titleLabel = titleLabel else {
            return nil
        }
        return self.toolBar.items?.first(where: { $0.customView == titleLabel })
    }
    
    private func removeTtileItem(animated: Bool) {
        guard let titleItem = self.getTtileItem() else {
            return
        }
        let items = self.toolBar.items?.filter({ $0 != titleItem })
        self.toolBar.setItems(items, animated: animated)
    }
    
    private func addTtileItem(animated: Bool) {
        guard self.getTtileItem() == nil else {
            return
        }
        if let label = self.createTtileLabel() {
            self.titleLabel = label
            let item = UIBarButtonItem(customView: label)
            var items = self.toolBar.items
            items?.append(item)
            self.toolBar.setItems(items, animated: animated)
        }
    }
    
}

extension STFilesActionTabBarAccessoryView {
    
    class func loadNib() -> STFilesActionTabBarAccessoryView {
        let contentView = Bundle(for: self).loadNibNamed(String(describing: self), owner: self, options: nil)?.first as! STFilesActionTabBarAccessoryView
        return contentView
    }
    
}
