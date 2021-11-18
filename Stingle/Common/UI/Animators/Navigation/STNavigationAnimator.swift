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
    func navigationAnimator(shouldAddInteractionDismiss animator: STNavigationAnimator.TransitioningOperation) -> Bool
}

protocol INavigationAnimatorSourceVC: INavigationAnimatorVC {
    
}

extension INavigationAnimatorDestinationVC {
    
    func navigationAnimator(shouldAddInteractionDismiss animator: STNavigationAnimator.TransitioningOperation) -> Bool {
        return true
    }
    
}

class STNavigationAnimator: NSObject {
    
    enum ContentMode {
        case fill
        case fit
    }
    
    private(set) var transitioningOperation: TransitioningOperation?
    private var interactivePops = STObserverEvents<TransitioningOperationInteractivePop>()
    
    private func addInteractionGesture(viewController: INavigationAnimatorDestinationVC, transitioningOperation: TransitioningOperation) {
        guard viewController.navigationAnimator(shouldAddInteractionDismiss: transitioningOperation) else {
            return
        }
        let interactive = TransitioningOperationInteractivePop(destinationVC: viewController)
        self.interactivePops.addObject(interactive)
    }
        
}

extension STNavigationAnimator: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let operationPop = animationController as? TransitioningOperationPop else {
            return nil
        }
        guard let interaction = self.interactivePops.objects.first(where: { $0.destinationVC == operationPop.destinationVC}), interaction.isInteractionDismiss else {
            return nil
        }
        interaction.dataSource = operationPop
        return interaction
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
            transitioning.delegate = self
            return transitioning
        case .pop:
            guard let destination = fromVC as? INavigationAnimatorDestinationVC, let source = toVC as? INavigationAnimatorSourceVC else {
                self.transitioningOperation = nil
                return nil
            }
            let transitioning = TransitioningOperationPop(destinationVC: destination, sourceVC: source)
            self.transitioningOperation = transitioning
            transitioning.delegate = self
            return transitioning
        default:
            self.transitioningOperation = nil
            return nil
        }
    }
    
}

extension STNavigationAnimator: STNavigationAnimatorTransitioningOperationDelegate {
    
    func transitioningOperation(didStartNavigate transitioningOperation: TransitioningOperation) {
        
    }
    
    func transitioningOperation(didStartAnimate transitioningOperation: TransitioningOperation) {
        
    }
    
    func transitioningOperation(didSEndNavigate transitioningOperation: TransitioningOperation) {
        if transitioningOperation.operation == .push {
            self.addInteractionGesture(viewController: transitioningOperation.destinationVC, transitioningOperation: transitioningOperation)
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
        var frame = self.bounds
        if let size = self.previewContentSizeNavigationAnimator() {
            frame = self.culculateDrawRect(contentSize: size)
        }
        let result = UIImageView(frame: frame)
        result.contentMode = self.contentMode
        result.image = self.image
        result.clipsToBounds = self.clipsToBounds
        return result
    }
    
}
