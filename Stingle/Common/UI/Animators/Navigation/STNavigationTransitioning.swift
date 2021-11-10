//
//  STNavigationTransitioning.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/10/21.
//

import UIKit

extension STNavigationAnimator {
    
    enum Operation {
        case push
        case pop
    }
    
    class TransitioningOperation: NSObject, UIViewControllerAnimatedTransitioning {
        
        let operation: Operation
        let destinationVC: INavigationAnimatorDestinationVC
        let sourceVC: INavigationAnimatorSourceVC
        let animationTime: TimeInterval = 0.3
        
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
            UIView.animate(withDuration: self.animationTime) {
                self.animateTransition(transitionContext: transitionContext)
            } completion: { _ in
                self.endTransition(transitionContext: transitionContext)
            }
        }
        
        //MARK: -  Working
        
        func startTransition(transitionContext: UIViewControllerContextTransitioning) {
            
        }
        
        func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
            transitionContext.updateInteractiveTransition(1)
        }
        
        func endTransition(transitionContext: UIViewControllerContextTransitioning) {
            transitionContext.finishInteractiveTransition()
            transitionContext.completeTransition(true)
        }
        
    }

}




