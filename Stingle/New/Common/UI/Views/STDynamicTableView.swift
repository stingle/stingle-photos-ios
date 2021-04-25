//
//  STDynamicTableView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/24/21.
//

import UIKit

class STDynamicTableView: UITableView {
    
    override var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        return self.contentSize
    }

}
