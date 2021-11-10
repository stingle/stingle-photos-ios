//
//  STNavigationAnimator.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/10/21.
//

import UIKit

protocol INavigationAnimatorSourceView: UIView {
    
    func previewContentSizeNavigationAnimator() -> CGSize?
    func createPreviewNavigationAnimator() -> UIView
    func previewContentModeNavigationAnimator() -> STNavigationAnimator.ContentMode
    
}

extension INavigationAnimatorSourceView {
    
    func culculateDrawRect(contentSize: CGSize) -> CGRect {
        
        let mode = self.previewContentModeNavigationAnimator()
        
        var scale = CGFloat.zero
        
        switch mode {
        case .fit:
            scale = min(self.frame.width / contentSize.width, self.frame.height / contentSize.height)
        case .fill:
            return self.bounds
        }
        
        var result = CGRect.zero
        result.size = CGSize(width: scale * contentSize.width, height: scale * contentSize.height)
        
        result.origin.x = (self.frame.width - result.width) / 2
        result.origin.y = (self.frame.height - result.height) / 2
        
        return result
        
    }
    
}

protocol INavigationAnimatorVC: UIViewController {
    
    func navigationAnimator(sendnerItem animator: STNavigationAnimator.TransitioningOperation) -> Any?
    func navigationAnimator(sourceView animator: STNavigationAnimator.TransitioningOperation, sendnerItem: Any?) -> INavigationAnimatorSourceView?
}

protocol INavigationAnimatorDestinationVC: INavigationAnimatorVC {
    
}

protocol INavigationAnimatorSourceVC: INavigationAnimatorVC {
    
}

class STNavigationAnimator: NSObject {
    
    enum ContentMode {
        case fill
        case fit
    }
    
    private(set) var transitioningOperation: TransitioningOperation?
    
}

extension STNavigationAnimator: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//        if self.isPresent || !self.isInteractiveDismiss {
//            return nil
//        }
        return nil
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        switch operation {
        case .push:
            guard let destination = toVC as? INavigationAnimatorDestinationVC, let source = fromVC as? INavigationAnimatorSourceVC else {
                self.transitioningOperation = nil
                return nil
            }
            let transitioning = TransitioningOperationPush(destinationVC: destination, sourceVC: source)
            self.transitioningOperation = transitioning
            return transitioning
        case .pop:
            guard let destination = fromVC as? INavigationAnimatorDestinationVC, let source = toVC as? INavigationAnimatorSourceVC else {
                self.transitioningOperation = nil
                return nil
            }
            let transitioning = TransitioningOperationPop(destinationVC: destination, sourceVC: source)
            self.transitioningOperation = transitioning
            return transitioning
        default:
            self.transitioningOperation = nil
            return nil
        }
    }
    
}

extension STImageView: INavigationAnimatorSourceView {
    
    func previewContentModeNavigationAnimator() -> STNavigationAnimator.ContentMode {
        switch self.contentMode {
        case .scaleAspectFit:
            return .fit
        default:
            return .fill
        }
    }
    
    
    func previewContentSizeNavigationAnimator() -> CGSize? {
        return self.image?.size
    }
    
    func createPreviewNavigationAnimator() -> UIView {
        let result = UIImageView(frame: self.bounds)
        result.contentMode = self.contentMode
        result.image = self.image
        result.clipsToBounds = self.clipsToBounds
        return result
    }
    
        
}
