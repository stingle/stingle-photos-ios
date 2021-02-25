//
//  ATLoadingView.swift
//  Kinodaran
//
//  Created by Khoren Asatryan on 8/10/20.
//  Copyright © 2020 Advanced Tech. All rights reserved.
//

import UIKit

class STLoadingView: UIView {

    static private let loadingViewTag = 212
    
    @IBOutlet weak var blurView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    class func show(in view: UIView, blurEffect: Bool = true) {
        var loadingView: STLoadingView
        if let myLoadingView = view.viewWithTag(self.loadingViewTag) as? STLoadingView {
            view.bringSubviewToFront(myLoadingView)
            loadingView = myLoadingView
        } else {
            loadingView = self.createLoadingView(blurEffect: blurEffect)
            loadingView.alpha = 0
            view.addSubviewFullContent(view: loadingView)
        }
        
		loadingView.activityIndicatorView.startAnimating()
        UIView.animate(withDuration: 0.3) {
            loadingView.alpha = 1
        }
    }
    
    class func hide(in view: UIView) {
        guard let loadingView = view.viewWithTag(self.loadingViewTag) as? STLoadingView else {
            return
        }
        
		loadingView.activityIndicatorView.stopAnimating()
        UIView.animate(withDuration: 0.3, animations: {
            loadingView.alpha = 0
        }) { (_) in
            loadingView.removeFromSuperview()
        }
    }
    
    //MARK: - Private methods
    
    private class func createLoadingView(blurEffect: Bool) -> STLoadingView {
        let nibs = Bundle.main.loadNibNamed("STLoadingView", owner: self, options: nil)
        guard let containerView = nibs?.first(where: {($0 as? UIView != nil)}) as? STLoadingView else {
            fatalError()
        }
        containerView.blurView.alpha = blurEffect ? 1 : 0
        containerView.tag = self.loadingViewTag
        return containerView
    }

}
