//
//  UIView+Helper.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 2/4/22.
//

import UIKit

extension UIView {

    static func loadView<T>(fromNib name: String, withType type: T.Type) -> T? {
        if let view = Bundle.main.loadNibNamed(name, owner: nil, options: nil)?.first as? T {
            return view
        }
        return nil
    }

    var left: CGFloat {
        get {
            return frame.minX
        }
        set(x) {
            var frame = standardizeRect(self.frame)

            frame.origin.x = x
            self.frame = frame
        }
    }

    var top: CGFloat {
        get {
            return frame.minY
        }
        set(y) {
            var frame = standardizeRect(self.frame)

            frame.origin.y = y
            self.frame = frame
        }
    }

    var right: CGFloat {
        get {
            return frame.maxX
        }
        set(right) {
            var frame = standardizeRect(self.frame)

            frame.origin.x = right - frame.size.width
            self.frame = frame
        }
    }

    var bottom: CGFloat {
        get {
            return frame.maxY
        }
        set(bottom) {
            var frame = standardizeRect(self.frame)

            frame.origin.y = bottom - frame.size.height
            self.frame = frame
        }
    }

    var width: CGFloat {
        get {
            return frame.width
        }
        set(width) {
            var frame = standardizeRect(self.frame)

            frame.size.width = width
            self.frame = frame
        }
    }

    var height: CGFloat {
        get {
            return frame.height
        }
        set(height) {
            var frame = standardizeRect(self.frame)

            frame.size.height = height
            self.frame = frame
        }
    }

    var centerX: CGFloat {
        get {
            return frame.midX
        }
        set(centerX) {
            center = CGPoint(x: centerX, y: center.y)
        }
    }

    var centerY: CGFloat {
        get {
            return center.y
        }
        set(centerY) {
            center = CGPoint(x: center.x, y: centerY)
        }
    }

    var size: CGSize {
        get {
            return standardizeRect(frame).size
        }
        set(size) {
            var frame = standardizeRect(self.frame)

            frame.size = size
            self.frame = frame
        }
    }

    private func standardizeRect(_ rect: CGRect) -> CGRect {
        return CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
    }

}
