//
//  STNavigationTransitioning.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/10/21.
//

import UIKit

protocol STNavigationAnimatorTransitioningOperationDelegate: AnyObject {
    
    func transitioningOperation(didStartNavigate transitioningOperation: STNavigationAnimator.TransitioningOperation)
    func transitioningOperation(didStartAnimate transitioningOperation: STNavigationAnimator.TransitioningOperation)
    func transitioningOperation(didSEndNavigate transitioningOperation: STNavigationAnimator.TransitioningOperation)
    
}

extension STNavigationAnimator {
    
    enum Operation {
        case push
        case pop
    }
    
    class TransitioningOperation: NSObject, UIViewControllerAnimatedTransitioning {
        
        let operation: Operation
        let destinationVC: INavigationAnimatorDestinationVC
        let sourceVC: INavigationAnimatorSourceVC
        let animationTime: TimeInterval = 0.35
        
        weak var delegate: STNavigationAnimatorTransitioningOperationDelegate?
        
        init(operation: Operation, destinationVC: INavigationAnimatorDestinationVC, sourceVC: INavigationAnimatorSourceVC) {
            self.operation = operation
            self.destinationVC = destinationVC
            self.sourceVC = sourceVC
            super.init()
        }
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return self.animationTime
        }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            self.startTransition(transitionContext: transitionContext)
            
            UIView.animate(withDuration: self.animationTime, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.animateTransition(transitionContext: transitionContext)
            } completion: { _ in
                self.endTransition(transitionContext: transitionContext)
            }
        }
        
        //MARK: -  Working
        
        func startTransition(transitionContext: UIViewControllerContextTransitioning) {
            self.delegate?.transitioningOperation(didStartNavigate: self)
        }
        
        func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
            transitionContext.updateInteractiveTransition(1)
            self.delegate?.transitioningOperation(didStartAnimate: self)
        }
        
        func endTransition(transitionContext: UIViewControllerContextTransitioning) {
            transitionContext.finishInteractiveTransition()
            transitionContext.completeTransition(true)
            self.delegate?.transitioningOperation(didSEndNavigate: self)
        }
        
    }

}




