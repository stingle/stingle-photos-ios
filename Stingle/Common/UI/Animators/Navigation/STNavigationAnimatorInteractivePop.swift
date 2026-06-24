//
//  STNavigationAnimatorInteractivePop.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/11/21.
//

import UIKit
import Darwin
import StingleRoot

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
        private var transitionContext: UIViewControllerContextTransitioning?
        private var transitionContextProgress: CGFloat = .zero

        /// Drag down at least this fraction of the screen height to dismiss on a slow release.
        private let dismissDistanceFactor: CGFloat = 0.15
        /// A downward flick this fast (pt/s) dismisses regardless of distance; an upward
        /// flick this fast always cancels. Matches the iOS Photos feel.
        private let dismissVelocityThreshold: CGFloat = 1000
        
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
            panGesture.allowedScrollTypesMask = .continuous
            panGesture.delegate = self
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
            // Native iOS Photos drives the dismiss off the *vertical* drag only: the photo
            // tracks the finger in both axes (set by the caller), but the fade/shrink and the
            // completion progress respond to how far down you've pulled — sideways drift does
            // not fade the screen or count toward dismissal.
            let verticalOffset = max(0, animatedPreview.center.y - translationCenter.y)
            let maxDistance = max(1, self.destinationVC.view.frame.height * 0.5)
            let progress = min(1, verticalOffset / maxDistance)
            self.destinationVC.view.alpha = 1 - progress
            self.transitionContext?.updateInteractiveTransition(progress)
            let scale = max(0.85, 1 - progress * 0.3)
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

            guard let panGesture = self.panGesture else {
                return
            }

            let translation = panGesture.translation(in: panGesture.view)
            let velocity = panGesture.velocity(in: panGesture.view)
            let distanceThreshold = self.destinationVC.view.frame.height * self.dismissDistanceFactor

            // Native rule: a fast downward flick dismisses regardless of distance, a fast
            // upward flick always cancels, otherwise dismiss only if dragged far enough down.
            let shouldDismiss: Bool
            if velocity.y > self.dismissVelocityThreshold {
                shouldDismiss = true
            } else if velocity.y < -self.dismissVelocityThreshold {
                shouldDismiss = false
            } else {
                shouldDismiss = translation.y > distanceThreshold
            }

            if shouldDismiss {
                self.endInteractionGesture(velocity: velocity.y)
            } else {
                self.interactionGestureDidCancelled()
            }
        }

        private func endInteractionGesture(velocity: CGFloat = 0) {
            guard let transitionContext = self.transitionContext else {
                return
            }
            let animationTime = self.dataSource?.animationTime ?? 0.3
            self.isInteractionDismiss = false
            // Carry the fling momentum into the completion spring so a fast flick keeps moving.
            let springVelocity = min(abs(velocity) / 1000, 3)
            UIView.animate(withDuration: animationTime, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: springVelocity, options: .curveEaseInOut) {
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

extension STNavigationAnimator.TransitioningOperationInteractivePop: UIGestureRecognizerDelegate {

    // Only own the gesture when the user is clearly pulling *down*. A horizontal swipe is
    // left to the page view controller (paging between photos); an upward or sideways drag
    // never starts a dismiss. When the photo is zoomed in, the drag belongs to the scroll
    // view (panning around the image), so we yield. This is what makes paging, panning a
    // zoomed photo, and swipe-to-dismiss feel separate instead of fighting each other.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? InteractionPanGesture, let view = panGesture.view else {
            return true
        }
        let translation = panGesture.translation(in: view)
        guard translation.y > 0, abs(translation.y) > abs(translation.x) else {
            return false
        }
        // Bail if the touch is over a zoomed-in scroll view (the image should pan, not dismiss).
        let location = panGesture.location(in: view)
        var hitView = view.hitTest(location, with: nil)
        while let current = hitView {
            if let scrollView = current as? UIScrollView, scrollView.zoomScale > scrollView.minimumZoomScale + 0.001 {
                return false
            }
            hitView = current.superview
        }
        return true
    }

}

extension STNavigationAnimator.TransitioningOperationInteractivePop {
    
    fileprivate class InteractionPanGesture: UIPanGestureRecognizer  {
        var userInfo: AnyObject?
    }
    
}
