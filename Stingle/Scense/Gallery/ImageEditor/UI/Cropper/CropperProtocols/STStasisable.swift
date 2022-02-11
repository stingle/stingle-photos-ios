//
//  STStasisable.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import UIKit

protocol STStasisable: AnyObject {
    var stasisTimer: Timer? { get set }
    var stasisThings: (() -> Void)? { get set }

    func stasisAndThenRun(_ closure: @escaping () -> Void)
    func cancelStasis()
}

extension STStasisable where Self: UIViewController {

    func stasisAndThenRun(_ closure: @escaping () -> Void) {
        self.cancelStasis()
        self.stasisTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
            self?.view.isUserInteractionEnabled = false
            if self?.stasisThings != nil {
                self?.stasisThings?()
            }
            self?.cancelStasis()
        })
        self.stasisThings = closure
    }

    func cancelStasis() {
        guard self.stasisTimer != nil else {
            return
        }
        self.stasisTimer?.invalidate()
        self.stasisTimer = nil
        self.stasisThings = nil
        self.view.isUserInteractionEnabled = true
    }
}
