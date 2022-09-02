//
//  UICollectionView+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/15/21.
//

import UIKit

public extension UICollectionView {
    
    enum Kind: Equatable {
        
        case global(name: String)
        case header
        case footer
        case cell
        
        var kind: String {
            switch self {
            case .global(let name):
                return name
            case .header:
                return UICollectionView.elementKindSectionHeader
            case .footer:
                return UICollectionView.elementKindSectionFooter
            case .cell:
                return ""
            }
        }
        
        static func == (lhs: Self, rhs: String) -> Bool {
            return lhs.kind == rhs
        }
        
    }

    func registrCell(nibName: String, identifier: String) {
        self.register(UINib(nibName: nibName, bundle: Bundle.main), forCellWithReuseIdentifier: identifier)
    }
    
    func register(kind: Kind, nibName: String, identifier: String) {
        switch kind {
        case .cell:
            self.registrCell(nibName: nibName, identifier: identifier)
        default:
            self.register(UINib(nibName: nibName, bundle: Bundle.main), forSupplementaryViewOfKind: kind.kind, withReuseIdentifier: identifier)
        }
    }
    
    func registerHeader(nibName: String, kind: String) {
        self.register(UINib(nibName: nibName, bundle: Bundle.main), forSupplementaryViewOfKind: kind, withReuseIdentifier: kind)
    }
    
    func registerHeader(nibName: String, identifier: String, kind: String = UICollectionView.elementKindSectionHeader) {
        self.register(UINib(nibName: nibName, bundle: Bundle.main), forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }
    
    func registerFooter(nibName: String, identifier: String) {
        self.register(UINib(nibName: nibName, bundle: Bundle.main), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: identifier)
    }
    
    //MARK: - Private methods
    
}

