//
//  STNavigationAnimatorInteractivePop.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/11/21.
//

import UIKit
import Darwin

protocol ITransitioningOperationInteractiveDataSource: AnyObject {
    
    var animatedPreview: UIView? { get }
    var animationTime: TimeInterval { get }
    
    func interactivePop(startTransition interactivePop: STNavigationAnimator.TransitioningOperationInteractivePop, transitionContext: UIViewControllerContextTransitioning)
    
    func interactivePop(animateTransition interactivePop: STNavigationAnimator.TransitioningOperationInteractivePop, transitionContext: UIViewControllerContextTransitioning)
    
    func interactivePop(endTransition interactivePop: STNavigationAnimator.TransitioningOperationInteractivePop, transitionContext: UIViewControllerContextTransitioning)
    
    func interactivePop(cancelTransition interactivePop: STNavigationAnimator.TransitioningOperationInteractivePop, transitionContext: UIViewControllerContextTransitioning)
}

extension STNavigationAnimator {
     
    class TransitioningOperationInteractivePop: NSObject {
        
        weak var dataSource: ITransitioningOperationInteractiveDataSource?
        
        weak private(set) var destinationVC: INavigationAnimatorDestinationVC!
        private(set) var isInteractionDismiss = false
        private var translationCenter: CGPoint?
        private var startTranslationPoint: CGPoint?
        private var transitionContext: UIViewControllerContextTransitioning?
        private var transitionContextProgress: CGFloat = .zero
        
        private weak var panGesture: InteractionPanGesture?
                
        init(destinationVC: INavigationAnimatorDestinationVC) {
            self.destinationVC = destinationVC
            super.init()
            self.addInteractionGesture()
        }
        
        //MARK: - Private methods
        
        private func addInteractionGesture() {
            let panGesture = InteractionPanGesture(target: self, action: #selector(interactionDismiss(panGesture:)))
            panGesture.userInfo = self
            self.panGesture = panGesture
            self.destinationVC.view.addGestureRecognizer(panGesture)
        }
        
        private func setupViews(transitionContext: UIViewControllerContextTransitioning) {
            self.dataSource?.interactivePop(startTransition: self, transitionContext: transitionContext)
        }
        
        private func updateTransitionContextProgress() {
            guard let animatedPreview = self.dataSource?.animatedPreview, let translationCenter = self.translationCenter else {
                STLogger.log(info: "updateTransitionContextProgress error")
                return
            }
            let previewCenter = animatedPreview.center
            let distance = sqrt(pow(previewCenter.x - translationCenter.x, 2) + pow(previewCenter.y - translationCenter.y, 2))
            let size = self.destinationVC.view.frame.size
            let maxDistance: CGFloat = min(size.width, size.height)
            let progress = min(1, distance / maxDistance)
            self.destinationVC.view.alpha = 1 - progress
            self.transitionContext?.updateInteractiveTransition(progress)
            let scale = max(0.7, 1 - progress)
            animatedPreview.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.transitionContextProgress = progress
        }
        
        private func interactionGestureDidChanged() {
            
                        
            guard let panGesture = self.panGesture else {
                STLogger.log(info: "interactionGestureDidChanged error")
                return
            }
            
            if self.translationCenter == nil, let animatedPreview = self.dataSource?.animatedPreview {
                self.translationCenter = animatedPreview.center
            }
            
            if self.startTranslationPoint == nil {
                self.startTranslationPoint = panGesture.location(in: panGesture.view)
            }
            
            guard let translationCenter = self.translationCenter else {
                return
            }
            
            
            let translation = panGesture.translation(in: panGesture.view)
            self.dataSource?.animatedPreview?.center = CGPoint(x: translation.x + translationCenter.x, y: translation.y + translationCenter.y)
            self.updateTransitionContextProgress()
        }
        
        private func interactionGestureDidCancelled(velocity: CGFloat? = nil) {
            guard let transitionContext = self.transitionContext else {
                STLogger.log(info: "interactionGestureDidCancelled error")
                return
            }
            
            let translationCenter = self.translationCenter
            let animationTime = self.dataSource?.animationTime ?? 0.3
            let velocity = velocity ?? .zero
            
            UIView.animate(withDuration: animationTime, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: velocity, options: .curveEaseInOut) {
                if let translationCenter = translationCenter {
                    self.dataSource?.animatedPreview?.center = translationCenter
                }
                self.updateTransitionContextProgress()
            } completion: { _ in
                transitionContext.cancelInteractiveTransition()
                self.dataSource?.interactivePop(cancelTransition: self, transitionContext: transitionContext)
            }
        }
        
        private func interactionGestureDidFinished() {
            
            guard let startTranslationPoint = self.startTranslationPoint, let panGesture = self.panGesture  else {
                return
            }
            
            let velocity = panGesture.velocity(in: panGesture.view)
            let velocityVector = STMat.Vector(velocity.x, velocity.y)
            if velocityVector.modul < 50 {
                if self.transitionContextProgress > 0.3 {
                    self.endInteractionGesture()
                } else {
                    self.interactionGestureDidCancelled()
                }
            } else {
                let currentPoint = panGesture.location(in: panGesture.view)
                let v1 = velocityVector
                let v2 = STMat.Vector(currentPoint, startTranslationPoint)
                let angel = v2.angel(v1)
                if angel < .pi / 4 {
                    self.interactionGestureDidCancelled()
                } else {
                    self.endInteractionGesture()
                }
            }
        }
        
        private func endInteractionGesture() {
            guard let transitionContext = self.transitionContext else {
                return
            }
            let animationTime = self.dataSource?.animationTime ?? 0.3
            self.isInteractionDismiss = false
            UIView.animate(withDuration: animationTime, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.dataSource?.interactivePop(animateTransition: self, transitionContext: transitionContext)
            } completion: { _ in
                transitionContext.finishInteractiveTransition()
                self.dataSource?.interactivePop(endTransition: self, transitionContext: transitionContext)
                self.clean()
            }
        }
                        
        private func clean() {
            self.panGesture?.userInfo = nil
        }
        
        //MARK: - Private user action
        
        @objc private func interactionDismiss(panGesture: InteractionPanGesture) {
            switch panGesture.state {
            case .began:
                self.isInteractionDismiss = true
                self.destinationVC.navigationController?.popViewController(animated: true)
                self.translationCenter = self.dataSource?.animatedPreview?.center
            case .changed:
                self.interactionGestureDidChanged()
            case .ended:
                self.interactionGestureDidFinished()
                self.isInteractionDismiss = false
            default:
                self.isInteractionDismiss = false
                STLogger.log(info: "interactionDismiss Cancelled error")
                self.interactionGestureDidCancelled()
                break
            }
        }
        
    }
    
}

extension STNavigationAnimator.TransitioningOperationInteractivePop: UIViewControllerInteractiveTransitioning {
    
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        self.setupViews(transitionContext: transitionContext)
    }
    
}

extension STNavigationAnimator.TransitioningOperationInteractivePop {
    
    fileprivate class InteractionPanGesture: UIPanGestureRecognizer  {
        var userInfo: AnyObject?
    }
    
}
