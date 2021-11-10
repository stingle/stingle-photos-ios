//
//  STNavigationAnimatorPush.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/10/21.
//

import UIKit

extension STNavigationAnimator {
     
    class TransitioningOperationPush: TransitioningOperation {
        
        private var sourcePreview: UIView?
        private var sourceView: INavigationAnimatorSourceView?
        private var destinationView: INavigationAnimatorSourceView?
        private var sendnerItem: Any?
        
        private var finalFrame: CGRect?
        
        init(destinationVC: INavigationAnimatorDestinationVC, sourceVC: INavigationAnimatorSourceVC) {
            super.init(operation: .push, destinationVC: destinationVC, sourceVC: sourceVC)
        }

        //MARK: - Override methods
        
        override func startTransition(transitionContext: UIViewControllerContextTransitioning) {
            super.startTransition(transitionContext: transitionContext)
            self.preperAnimation(transitionContext: transitionContext)
        }
        
        override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
            super.animateTransition(transitionContext: transitionContext)
            self.reloadEndFrame(transitionContext: transitionContext)
            self.sourcePreview?.frame = self.finalFrame ?? transitionContext.containerView.bounds
            self.destinationVC.view.alpha = 1
        }
        
        override func endTransition(transitionContext: UIViewControllerContextTransitioning) {
            self.destinationView?.isHidden = false
            self.sourceView?.isHidden = false
            self.sourcePreview?.removeFromSuperview()
            super.endTransition(transitionContext: transitionContext)
        }
        
        //MARK: - private methods
        
        private func preperAnimation(transitionContext: UIViewControllerContextTransitioning) {
            self.sendnerItem = self.sourceVC.navigationAnimator(sendnerItem: self)
            self.addDestinationVC(transitionContext: transitionContext)
            self.addPreview(transitionContext: transitionContext)
        }
        
        private func addDestinationVC(transitionContext: UIViewControllerContextTransitioning) {
            if let destinationView = self.destinationVC.navigationAnimator(sourceView: self, sendnerItem: self.sendnerItem) {
                self.finalFrame = transitionContext.containerView.convert(destinationView.bounds, from: destinationView)
                self.destinationView = destinationView
                self.destinationVC.view.alpha = .zero
                destinationView.isHidden = true
            }
           
            self.destinationVC.view.frame = transitionContext.finalFrame(for: self.destinationVC)
            transitionContext.containerView.addSubview(self.destinationVC.view)
            self.destinationVC.view.layoutIfNeeded()
        }
        
        private func addPreview(transitionContext: UIViewControllerContextTransitioning) {
            guard let sourceView = self.sourceVC.navigationAnimator(sourceView: self, sendnerItem: self.sendnerItem) else {
                return
            }
            let preview = sourceView.createPreviewNavigationAnimator()
            let frame = transitionContext.containerView.convert(sourceView.bounds, from: sourceView)
            preview.frame = frame
            sourceView.isHidden = true
            transitionContext.containerView.addSubview(preview)
            self.sourceView = sourceView
            self.sourcePreview = preview
        }
        
        private func reloadEndFrame(transitionContext: UIViewControllerContextTransitioning) {
            guard let destinationView = self.destinationView else { return  }
            guard let contentSize = (destinationView.previewContentSizeNavigationAnimator() ?? self.sourceView?.previewContentSizeNavigationAnimator()) else { return }
            let finalFrame = destinationView.culculateDrawRect(contentSize: contentSize)
            self.finalFrame = transitionContext.containerView.convert(finalFrame, from: destinationView)
        }
        
    }
    
}
