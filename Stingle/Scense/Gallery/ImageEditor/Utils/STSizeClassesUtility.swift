//
//  STSizeClassesUtility.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 12/28/21.
//

import UIKit

class STSizeClassesUtility {

    class func isBothRegular(collection: UITraitCollection) -> Bool {
        return collection.horizontalSizeClass == .regular && collection.verticalSizeClass == .regular
    }

    class func isBothCompact(collection: UITraitCollection) -> Bool {
        return collection.horizontalSizeClass == .compact && collection.verticalSizeClass == .compact
    }

    class func isWidthRegular(collection: UITraitCollection) -> Bool {
        return collection.horizontalSizeClass == .regular
    }

    class func isHeightRegular(collection: UITraitCollection) -> Bool {
        return collection.verticalSizeClass == .regular
    }

    class func isCompactRegular(collection: UITraitCollection) -> Bool {
        return collection.horizontalSizeClass == .compact && collection.verticalSizeClass == .regular
    }


}
