//
//  STCropScrollViewContainer.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import UIKit

class STCropScrollViewContainer: UIView {
    var scrollView: UIScrollView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        if view == self {
            return self.scrollView
        }

        return view
    }
}
