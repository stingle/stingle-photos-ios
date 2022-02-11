//
//  STDynamicTableView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/24/21.
//

import UIKit

protocol STDynamicTableViewDelegate: UITableViewDelegate {
    
    func dynamicTableView(didChanged tableView: STDynamicTableView, contentSize: CGSize)
    
}

@IBDesignable
class STDynamicTableView: UITableView {
    
    override var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
            (self.delegate as? STDynamicTableViewDelegate)?.dynamicTableView(didChanged: self, contentSize: self.contentSize)
        }
    }

    override var intrinsicContentSize: CGSize {
        return self.contentSize
    }

}
