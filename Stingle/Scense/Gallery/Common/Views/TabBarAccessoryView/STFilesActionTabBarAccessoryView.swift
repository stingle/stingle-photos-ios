//
//  STAlbumFilesTabBarAccessoryView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/1/21.
//

import UIKit
import StingleRoot

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
            let image = UIImage(systemName: "square.and.arrow.up")
            let result = ActionItem(title: "share".localized, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }

        static func move(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(systemName: "folder")
            let result = ActionItem(title: "move".localized, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }

        static func saveToDevice(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(systemName: "square.and.arrow.down")
            let result = ActionItem(title: "save".localized, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }

        static func trash(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .systemRed) -> ActionItem {
            let image = UIImage(systemName: "trash")
            let result = ActionItem(title: "trash".localized, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }

        static func recover(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(systemName: "arrow.uturn.backward")
            let result = ActionItem(title: "recover".localized, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }

        static func deleteAll(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .systemRed) -> ActionItem {
            let image = UIImage(systemName: "trash")
            let result = ActionItem(title: "delete_all".localized, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }

        static func recoverAll(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(systemName: "arrow.uturn.backward")
            let result = ActionItem(title: "recover_all".localized, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
            return result
        }

        static func edit(identifier: StringPointer?, handler: @escaping ((Self, UIBarButtonItem) -> Void), tintColor: UIColor = .appText) -> ActionItem {
            let image = UIImage(systemName: "slider.horizontal.3")
            let result = ActionItem(title: "edit".localized, image: image, tintColor: tintColor, handler: handler, identifier: identifier)
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

    override func awakeFromNib() {
        super.awakeFromNib()
        let appearance = UIToolbarAppearance()
        appearance.configureWithDefaultBackground()
        self.toolBar.standardAppearance = appearance
        self.toolBar.compactAppearance = appearance
        self.toolBar.scrollEdgeAppearance = appearance
    }

    func setEnabled(isEnabled: Bool) {
        self.toolBar.items?.forEach({ item in
            guard let item = item as? ButtonItem else { return }
            item.isEnabled = isEnabled
            (item.customView as? UIButton)?.isEnabled = isEnabled
        })
    }

    func reloadData() {
        guard let dataSource = self.dataSource else {
            self.toolBar.setItems(nil, animated: false)
            return
        }
        let actions = dataSource.accessoryView(actions: self)

        // Evenly distribute the action buttons across the bar (flexible spaces
        // on both ends and between items) instead of left-aligned fixed gaps.
        var items: [UIBarButtonItem] = [.flexibleSpace()]
        actions.forEach { action in
            items.append(self.makeButtonItem(for: action))
            items.append(.flexibleSpace())
        }
        self.toolBar.setItems(items, animated: false)
    }

    private func makeButtonItem(for action: ActionItem) -> ButtonItem {
        var config = UIButton.Configuration.plain()
        config.image = action.image
        config.title = action.title
        config.imagePlacement = .top
        config.imagePadding = 2
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 8, bottom: 3, trailing: 8)
        config.baseForegroundColor = action.tintColor
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.regular(light: 11)
            return out
        }
        let button = UIButton(configuration: config)
        let item = ButtonItem(customView: button)
        item.actionItem = action
        button.addAction(UIAction { [weak item] _ in
            guard let item = item, let actionItem = item.actionItem else { return }
            actionItem.handler(actionItem, item)
        }, for: .touchUpInside)
        return item
    }
    
    func barButtonItem(for identifier: StringPointer?) -> UIBarButtonItem? {
        self.toolBar.items?.first(where: { ($0 as? ButtonItem)?.actionItem?.identifier?.stringValue == identifier?.stringValue })
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
