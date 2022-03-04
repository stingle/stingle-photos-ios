//
//  STNavigationAnimatorPop.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/10/21.
//

import UIKit

extension STNavigationAnimator {
     
    class TransitioningOperationPop: TransitioningOperation {
        
        private var sendnerItem: Any?
        private var sourceView: INavigationAnimatorSourceView?
        private var destinationView: INavigationAnimatorSourceView?
        private var destinationPreview: UIView?
        private var finalFrame: CGRect?
        
        init(destinationVC: INavigationAnimatorDestinationVC, sourceVC: INavigationAnimatorSourceVC) {
            super.init(operation: .pop, destinationVC: destinationVC, sourceVC: sourceVC)
        }
        
        //MARK: - Override methods
        
        override func startTransition(transitionContext: UIViewControllerContextTransitioning) {
            super.startTransition(transitionContext: transitionContext)
            self.preperAnimation(transitionContext: transitionContext)
        }
        
        override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
            super.animateTransition(transitionContext: transitionContext)
            self.destinationPreview?.frame = self.finalFrame ?? .zero
            self.destinationPreview?.layoutIfNeeded()
            self.destinationVC.view.alpha = .zero
        }
        
        override func endTransition(transitionContext: UIViewControllerContextTransitioning) {
            self.sourceView?.isHidden = false
            self.destinationPreview?.removeFromSuperview()
            super.endTransition(transitionContext: transitionContext)
        }
        
        //MARK: - Private methods
        
        private func preperAnimation(transitionContext: UIViewControllerContextTransitioning) {
            self.addSsourceVCView(transitionContext: transitionContext)
            self.sendnerItem = self.destinationVC.navigationAnimator(sendnerItem: self)
            self.sourceView = self.sourceVC.navigationAnimator(sourceView: self, sendnerItem: self.sendnerItem)
            self.destinationView = self.destinationVC.navigationAnimator(sourceView: self, sendnerItem: self.sendnerItem)
            self.destinationPreview = self.destinationView?.createPreviewNavigationAnimator()
            if let sourceView = self.sourceView {
                self.destinationPreview?.contentMode = sourceView.contentMode
                self.destinationPreview?.clipsToBounds = sourceView.clipsToBounds
            }
            self.addSetupViews(transitionContext: transitionContext)
            self.reloadEndFrame(transitionContext: transitionContext)
        }
        
        private func addSsourceVCView(transitionContext: UIViewControllerContextTransitioning) {
            let finalFrame = transitionContext.finalFrame(for: self.sourceVC)
            self.sourceVC.view.frame = finalFrame
            if self.sourceVC.view.superview == nil {
                transitionContext.containerView.insertSubview(self.sourceVC.view, at: .zero)
            }
            self.sourceVC.view.layoutIfNeeded()
        }
        
        private func addSetupViews(transitionContext: UIViewControllerContextTransitioning) {
            guard let destinationPreview = self.destinationPreview else {
                return
            }
            let frame = transitionContext.containerView.convert(destinationPreview.frame, from: self.destinationView)
            destinationPreview.frame = frame
            transitionContext.containerView.addSubview(destinationPreview)
            self.destinationView?.isHidden = true
            self.sourceView?.isHidden = true
        }
        
        private func reloadEndFrame(transitionContext: UIViewControllerContextTransitioning) {
            guard let sourceView = self.sourceView else { return  }
            guard let contentSize = (sourceView.previewContentSizeNavigationAnimator() ?? self.destinationView?.previewContentSizeNavigationAnimator()) else { return }
            let finalFrame = sourceView.culculateDrawRect(contentSize: contentSize)
            self.finalFrame = transitionContext.containerView.convert(finalFrame, from: sourceView)
        }
        
    }
    
}

extension STNavigationAnimator.TransitioningOperationPop: ITransitioningOperationInteractiveDataSource {
   
    var animatedPreview: UIView? {
        return self.destinationPreview
    }
    
    func interactivePop(startTransition interactivePop: STNavigationAnimator.TransitioningOperationInteractivePop, transitionContext: UIViewControllerContextTransitioning) {
        self.startTransition(transitionContext: transitionContext)
    }
    
    func interactivePop(animateTransition interactivePop: STNavigationAnimator.TransitioningOperationInteractivePop, transitionContext: UIViewControllerContextTransitioning) {
        self.animateTransition(transitionContext: transitionContext)
    }
    
    func interactivePop(endTransition interactivePop: STNavigationAnimator.TransitioningOperationInteractivePop, transitionContext: UIViewControllerContextTransitioning) {
        self.endTransition(transitionContext: transitionContext)
    }
    
    func interactivePop(cancelTransition interactivePop: STNavigationAnimator.TransitioningOperationInteractivePop, transitionContext: UIViewControllerContextTransitioning) {
        self.destinationPreview?.removeFromSuperview()
        self.sourceView?.isHidden = false
        self.destinationView?.isHidden = false
        transitionContext.completeTransition(false)
    }
    
}


