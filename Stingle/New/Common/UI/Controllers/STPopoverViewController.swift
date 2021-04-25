//
//  STPopoverViewController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/21/21.
//

import UIKit

class STPopoverViewController: UIViewController {
    
    private(set) var setupPreferredContentSize: CGSize = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupPreferredContentSize = self.preferredContentSize
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updatePreferredContentSize()
    }
    
    func calculatePreferredContentSize() -> CGSize {
        var size = self.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if self.setupPreferredContentSize.width > 0 {
            size.width = min(self.self.setupPreferredContentSize.width, size.width)
        }
        if self.setupPreferredContentSize.height > 0 {
            size.height = min(self.setupPreferredContentSize.height, size.height)
        }
        return size
    }
    
    func updatePreferredContentSize() {
        self.preferredContentSize = self.calculatePreferredContentSize()
    }
    

}
