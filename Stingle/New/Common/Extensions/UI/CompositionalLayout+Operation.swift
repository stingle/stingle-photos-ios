//
//  CompositionalLayout+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/20/21.
//

import UIKit

extension NSCollectionLayoutSection {
    
    func removeContentInsetsReference(safeAreaInsets: UIEdgeInsets?) {
        if #available(iOS 14.0, tvOS 14.0, *) {
            self.contentInsetsReference = .none
        } else if let safeAreaInsets = safeAreaInsets {
            var contentInsets = self.contentInsets
            contentInsets.leading = contentInsets.leading - safeAreaInsets.left
            contentInsets.trailing = contentInsets.trailing - safeAreaInsets.right
            self.contentInsets = contentInsets
        }
    }
    
}
