//
//  ATNavigationAnimator.swift
//  Kinodaran
//
//  Created by Khoren on 4/9/20.
//  Copyright © 2020 Advanced Tech. All rights reserved.
//

import UIKit

protocol INavigationAnimatorEvents: AnyObject {
    
    func navigationAnimator(didBeginInteractive navigationAnimator: INavigationAnimator)
    
    func navigationAnimator(startPresentAnimation navigationAnimator: INavigationAnimator)
    func navigationAnimator(presentAnimation navigationAnimator: INavigationAnimator)
    func navigationAnimator(endPresentAnimation navigationAnimator: INavigationAnimator)
    
    func navigationAnimator(startDismissAnimation navigationAnimator: INavigationAnimator)
    func navigationAnimator(dismissAnimation navigationAnimator: INavigationAnimator)
    func navigationAnimator(endDismissAnimation navigationAnimator: INavigationAnimator)
    
}

protocol INavigationAnimatorSource: UIViewController, INavigationAnimatorEvents {
    func navigationAnimator(sourceViewFor navigationAnimator: INavigationAnimator) -> UIView?
}

extension INavigationAnimatorEvents {
    
    func navigationAnimator(didBeginInteractive navigationAnimator: INavigationAnimator) {}
    
    func navigationAnimator(startPresentAnimation navigationAnimator: INavigationAnimator) {}
    func navigationAnimator(presentAnimation navigationAnimator: INavigationAnimator) {}
    func navigationAnimator(endPresentAnimation navigationAnimator: INavigationAnimator) {}
    
    func navigationAnimator(startDismissAnimation navigationAnimator: INavigationAnimator) {}
    func navigationAnimator(dismissAnimation navigationAnimator: INavigationAnimator) {}
    func navigationAnimator(endDismissAnimation navigationAnimator: INavigationAnimator) {}
    
}

 protocol INavigationAnimatorDestination: UIViewController, INavigationAnimatorEvents {
    
    var navigationAnimator: INavigationAnimator { get }
    
    func navigationAnimator(destinationViewFor navigationAnimator: INavigationAnimator) -> UIView?
    func navigationAnimator(isDetailPresentation navigationAnimator: INavigationAnimator) -> Bool
    func navigationAnimator(shouldBeginInteractive navigationAnimator: INavigationAnimator) -> Bool
    func navigationAnimator(canAddInteractiveDismiss navigationAnimator: INavigationAnimator) -> Bool
    
}

extension INavigationAnimatorDestination {
    
    var presentingView: UIView? {
        return self.navigationAnimator.presentingView
    }
    
    func navigationAnimator(canAddInteractiveDismiss navigationAnimator: INavigationAnimator) -> Bool {
        return true
    }
        
    var controllerView: UIView? {
        return self.navigationAnimator.controllerView
    }
    
    func navigationAnimator(shouldBeginInteractive navigationAnimator: INavigationAnimator) -> Bool {
        return true
    }

}

protocol INavigationAnimator: UINavigationControllerDelegate, UIViewControllerAnimatedTransitioning {
    func setupTransitioning(for navigationController: UINavigationController, viewController: INavigationAnimatorDestination)
    func setupTransitioning(for viewController: INavigationAnimatorDestination)
    
    var isAnimated: Bool { get }
    var presentingView: UIView? { get }
    var controllerView: UIView? { get }
    var animatorSource: INavigationAnimatorSource? { get }
    var animatorDestination: INavigationAnimatorDestination? { get }
    var animatorOperation: STNavigationAnimator.AnimatorOperation { get }
    
}

class STNavigationAnimator: NSObject {
    
    enum AnimatorOperation {
        case present
        case dissmis
    }
    
    weak var animatorSourceController: INavigationAnimatorSource?
    
    private weak var containerView: UIView?
    private weak var controllerBackgroundView: UIView?
    private weak var transitionContext: UIViewControllerContextTransitioning?
    private weak var dismissGesture: UIPanGestureRecognizer? = nil
    private weak var dismissTapGesture: UITapGestureRecognizer? = nil
    private(set) var operation: UINavigationController.Operation = .none
    
    private var interactiveStartingPoint: CGPoint = .zero
    private var interactiveStartingSize: CGSize = .zero
    private var isInteractiveDismiss = false
    private var isEnableInteractiveDismiss = true
   
    private var isDetail = false
    private var requardIsDetail = false
    private var sourceView: UIView?
    private var destinationView: UIView?
    private var isDefaultDissmis = false
    
    private let blurEffectViewMinAlpha: CGFloat = 0
    private let blurEffectViewMaxAlpha: CGFloat = 1
    private let blurEffectViewTag: Int = 1022
    private var backroundBlurEffectViewView: UIView? = nil
    
    private(set) weak var fromViewController: UIViewController?
    private(set) weak var toViewController: UIViewController?
    private(set) var isAnimated: Bool = false
    private var isPresent: Bool = true
    private var animateTime: TimeInterval = 0.2
    private var interactiveTransition: CGFloat = 0
        
    var animatorSource: INavigationAnimatorSource? {
        return  self.animatorSourceController ?? self.fromViewController as? INavigationAnimatorSource
    }
    
    var animatorDestination: INavigationAnimatorDestination? {
        return self.toViewController as? INavigationAnimatorDestination
    }
    
    private var isNavigation: Bool {
        return self.operation != .none
    }
    
    //MARK: - Events
    
    private func sendEventDidBeginInteractive() {
        self.animatorDestination?.navigationAnimator(didBeginInteractive: self)
        self.animatorSource?.navigationAnimator(didBeginInteractive: self)
    }
    
    private func sendEventStartPresentAnimation() {
        self.animatorDestination?.navigationAnimator(startPresentAnimation: self)
        self.animatorSource?.navigationAnimator(startPresentAnimation: self)
    }
    
    private func sendEventPresentAnimation() {
        self.animatorDestination?.navigationAnimator(presentAnimation: self)
        self.animatorSource?.navigationAnimator(presentAnimation: self)
    }
    
    private func sendEventEndPresentAnimation() {
        self.animatorDestination?.navigationAnimator(endPresentAnimation: self)
        self.animatorSource?.navigationAnimator(endPresentAnimation: self)
    }
    
    private func sendEventStartDismissAnimation() {
        self.animatorDestination?.navigationAnimator(startDismissAnimation: self)
        self.animatorSource?.navigationAnimator(startDismissAnimation: self)
    }
    
    private func sendEventDismissAnimation() {
        self.animatorDestination?.navigationAnimator(dismissAnimation: self)
        self.animatorSource?.navigationAnimator(dismissAnimation: self)
    }
    
    private func sendEventEndDismissAnimation() {
        self.animatorDestination?.navigationAnimator(endDismissAnimation: self)
        self.animatorSource?.navigationAnimator(endDismissAnimation: self)
    }
        
    //MARK: - Present animate
    
    private func presentCntroller(transitionContext: UIViewControllerContextTransitioning) {
        self.isAnimated = true
        self.preparePresentCntroller(transitionContext: transitionContext)
        let containerView = transitionContext.containerView
        UIView.animate(withDuration: self.animateTime, animations: {
            self.presentAnimation(containerView: containerView)
        }) { (_) in
            self.presentEndAnimation(transitionContext: transitionContext, isCompleted: true)
            self.isAnimated = false
        }
    }
    
    private func preparePresentCntroller(transitionContext: UIViewControllerContextTransitioning) {
        self.fromViewController = transitionContext.viewController(forKey: .from)
        self.toViewController = transitionContext.viewController(forKey: .to)
        self.addControllerView(transitionContext: transitionContext)
    }
    
    private func addControllerView(transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        self.containerView = transitionContext.containerView
                
        self.refreshDetail()
        self.updateNavigationViews()
        let containerView = transitionContext.containerView
        
        let bgView = UIView(frame: containerView.bounds)
        bgView.clipsToBounds = true
        containerView.addSubview(bgView)
        
        guard let toView = self.toViewController?.view else {
            return
        }
        
        self.controllerBackgroundView = bgView
        bgView.addSubview(toView)
        self.setupPresentation()
        self.addBlurViewIfNeedded(transitionContext: transitionContext)
    }
    
    private func addBlurViewIfNeedded(transitionContext: UIViewControllerContextTransitioning) {
        let canAddBlurView = transitionContext.containerView.viewWithTag(self.blurEffectViewTag) == nil || self.operation == .none
        if let fromView = self.fromViewController?.view, canAddBlurView  {
            let blurView = self.createBlurEffectView(frame: fromView.bounds)
            fromView.addSubview(blurView)
            self.backroundBlurEffectViewView = blurView
        }
    }
    
    private func presentAnimation(containerView: UIView) {
        self.backroundBlurEffectViewView?.alpha = self.blurEffectViewMaxAlpha
        self.toViewController?.view?.transform = .identity
        self.controllerBackgroundView?.frame = containerView.bounds
        self.toViewController?.view.frame = self.finalFrame()
        self.sendEventPresentAnimation()
    }
    
    private func presentEndAnimation(transitionContext: UIViewControllerContextTransitioning, isCompleted: Bool) {
        self.controllerBackgroundView?.removeFromSuperview()
        if let toView = self.toViewController?.view {
            self.containerView?.addSubview(toView)
            self.updateConstraint()
        }
        transitionContext.completeTransition(isCompleted)
        self.insertOldViewIfNeeded()
        self.addGesture()
        if !self.isInteractiveDismiss {
            self.sendEventEndPresentAnimation()
        }
    }
    
    private func insertOldViewIfNeeded() {
        guard let toView = self.toViewController?.view, let superview = self.toViewController?.view.superview , let fromView = self.fromViewController?.view, fromView.superview == nil, superview.viewWithTag(self.blurEffectViewTag) == nil, UIDevice.current.userInterfaceIdiom != .tv else {
            return
        }
        for (index, view) in superview.subviews.enumerated() {
            if toView == view {
                superview.insertSubview(fromView, at: index)
                superview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                break
            }
        }
    }
    
    private func insertFromViewIfNeeded() {
        guard let toView = self.toViewController?.view, let superview = self.toViewController?.view.superview , let fromView = self.fromViewController?.view, fromView.superview == nil else {
            return
        }
        for (index, view) in superview.subviews.enumerated() {
            if toView == view {
                superview.insertSubview(fromView, at: index)
                if fromView.viewWithTag(self.blurEffectViewTag) == nil {
                    var controllerView = fromView
                    if let view = (self.fromViewController as? INavigationAnimatorDestination)?.controllerView {
                        controllerView = view
                    }
                    let blurView = self.createBlurEffectView(frame: controllerView.bounds)
                    controllerView.addSubview(blurView)
                    blurView.alpha = self.blurEffectViewMaxAlpha
                }
                superview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                break
            }
        }
    }
    
    //MARK: - Dismiss animate
    
    private func dismissCntroller(transitionContext: UIViewControllerContextTransitioning) {
        self.isAnimated = true
        self.prepareDismissCntroller(transitionContext: transitionContext)
        let containerView = transitionContext.containerView
        UIView.animate(withDuration: self.animateTime, animations: {
            self.dismissAnimation(containerView: containerView)
        }) { (_) in
            self.dismissEndAnimation(transitionContext: transitionContext)
            self.isAnimated = false
        }
    }
    
    private func prepareDismissCntroller(transitionContext: UIViewControllerContextTransitioning) {
        if self.fromViewController != transitionContext.viewController(forKey: .to) {
            self.isDefaultDissmis = true
        }
        
        self.fromViewController = transitionContext.viewController(forKey: .to)
        self.toViewController = transitionContext.viewController(forKey: .from)
        
        self.insertFromViewIfNeeded()
        if let view = self.fromViewController?.view.viewWithTag(self.blurEffectViewTag), self.operation != .none {
            self.backroundBlurEffectViewView = view
        }

        guard let toView = self.toViewController?.view else {
            return
        }
        self.updateNavigationViews()
        let containerView = transitionContext.containerView
        toView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        let bgView = UIView(frame: containerView.bounds)
        bgView.clipsToBounds = true
        containerView.addSubview(bgView)
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bgView.addSubview(toView)

        self.controllerBackgroundView = bgView
        containerView.layoutIfNeeded()
        self.sendEventStartDismissAnimation()
    }
    
    private func dismissAnimation(containerView: UIView) {
        self.sendEventDismissAnimation()
        self.backroundBlurEffectViewView?.alpha = self.blurEffectViewMinAlpha
        if let sourceView = self.sourceView, let sv = containerView.superview {
            let sourceViewRect = sv.convert(sourceView.bounds, from: sourceView)
            self.controllerBackgroundView?.frame = sourceViewRect
        }
        let transform = self.culculatePresentationTransform()
        self.toViewController?.view?.transform = transform
    }
    
    private func dismissEndAnimation(transitionContext: UIViewControllerContextTransitioning) {
        self.backroundBlurEffectViewView?.removeFromSuperview()
        self.sendEventEndDismissAnimation()
        self.controllerBackgroundView?.removeFromSuperview()
        transitionContext.completeTransition(true)
    }
    
    //MARK: - Private
    
    private func createBlurEffectView(frame: CGRect) -> UIView {
        let blurView = UIView(frame: frame)//ATBlurView.create(frame: frame)
        blurView.backgroundColor = .red.withAlphaComponent(0.8)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.tag = self.blurEffectViewTag
        blurView.alpha = self.blurEffectViewMinAlpha
        return blurView
    }
    
    private func refreshDetail() {
        self.isDetail = self.calculateDetail()
    }
    
    private func calculateDetail() -> Bool {
        let isDetail = self.animatorDestination?.navigationAnimator(isDetailPresentation: self) ?? false
        self.requardIsDetail = isDetail
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        return isDetail && isPad
    }
    
    private func updateConstraint() {
        guard let view = self.toViewController?.view else {
            return
        }
        view.translatesAutoresizingMaskIntoConstraints = true
        view.frame = self.finalFrame()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func setupPresentation() {
        if let containerView = self.containerView, let sourceView = self.sourceView {
            let sourceViewRect = containerView.convert(sourceView.frame, from: sourceView.superview)
            self.controllerBackgroundView?.frame = sourceViewRect
        }
        let transform = self.culculatePresentationTransform()
        self.toViewController?.view.transform = transform
        self.sendEventStartPresentAnimation()
    }
    
    private func culculatePresentationTransform() -> CGAffineTransform {
        guard let sourceView = self.sourceView, let destinationView = self.destinationView, let toView = self.toViewController?.view, let superview = toView.superview, !self.isDefaultDissmis else {
            return self.culculateDefaultPresentationTransform()
        }
        var sourceViewRect = superview.convert(sourceView.frame, from: sourceView.superview)
        let minScaled = max(sourceViewRect.width / destinationView.frame.width, sourceViewRect.height / destinationView.frame.height)
        let size = CGSize(width: destinationView.frame.width * minScaled, height: destinationView.frame.height * minScaled)
        
        sourceViewRect.origin.x = sourceViewRect.midX - size.width / 2
        sourceViewRect.origin.y = sourceViewRect.midY - size.height / 2
        sourceViewRect.size = size
        
        let destinationViewRect = superview.convert(destinationView.bounds, from: destinationView)
        let transform = self.transformFromRect(from: destinationViewRect, toRect: sourceViewRect)
        let toViewNewFrame = toView.frame.applying(transform)
        let resultTransform = self.transformFromViews(from: toView.frame, toRect: toViewNewFrame)
        
        return resultTransform
    }
    
    private func updateNavigationViews () {
        self.destinationView = self.animatorDestination?.navigationAnimator(destinationViewFor: self) ?? self.toViewController?.view
        self.sourceView = self.animatorSource?.navigationAnimator(sourceViewFor: self)
    }
    
    private func culculateDefaultPresentationTransform() -> CGAffineTransform {
        guard let containerView = self.containerView, let view = self.toViewController?.view else {
            return .identity
        }
        let transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height - view.frame.minY)
        return transform
    }
    
    private func transformFromRect(from: CGRect, toRect to: CGRect) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        transform = transform.concatenating(CGAffineTransform(translationX: -from.origin.x, y: -from.origin.y))
        transform = transform.concatenating(CGAffineTransform(scaleX: 1/from.size.width, y: 1/from.size.height))
        transform = transform.concatenating(CGAffineTransform(scaleX: to.size.width, y: to.size.height))
        transform = transform.concatenating(CGAffineTransform(translationX: to.origin.x, y: to.origin.y))
        return transform
    }
    
    private func transformFromViews(from: CGRect, toRect to: CGRect) -> CGAffineTransform {
        let transform = CGAffineTransform(translationX: to.midX-from.midX, y: to.midY-from.midY)
        return transform.scaledBy(x: to.width/from.width, y: to.height/from.height)
    }
    
    private func finalFrame() -> CGRect {
        guard let toViewController = self.toViewController, let transitionContext = self.transitionContext else {
            return self.toViewController?.view.frame ?? .zero
        }
        if self.isInteractiveDismiss {
            return transitionContext.initialFrame(for: toViewController)
        } else {
            return transitionContext.finalFrame(for: toViewController)
        }
    }
    
    private func startDismiss() {
        if self.isNavigation {
            self.toViewController?.navigationController?.popViewController(animated: true)
        } else {
            self.toViewController?.dismiss(animated: true, completion: nil)
        }
        self.sendEventDidBeginInteractive()
    }
    
    private func addGesture() {
        self.removeGesture()
        
        guard let canAddInteractiveDismiss = self.animatorDestination?.navigationAnimator(canAddInteractiveDismiss: self), canAddInteractiveDismiss == true else {
            return
        }
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.interactiveTransitioningGesture(gesture:)))
        gesture.delegate = self
        
        self.toViewController?.view.addGestureRecognizer(gesture)
        self.dismissGesture = gesture
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(interactiveTapTransitioningGesture(gesture:)))
        self.toViewController?.view.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
        self.dismissTapGesture = tapGesture
    }
    
    private func removeGesture() {
        if let gesture = self.dismissGesture {
            self.toViewController?.view.removeGestureRecognizer(gesture)
        }
        
        if let gesture = self.dismissTapGesture {
            self.toViewController?.view.removeGestureRecognizer(gesture)
        }
    }
    
    @objc private func interactiveTapTransitioningGesture(gesture: UIPanGestureRecognizer) {
        guard (self.toViewController?.view != nil), self.isEnableInteractiveDismiss else {
            return
        }
        self.startDismiss()
        self.dismisInteractive()
    }
    
    @objc private func interactiveTransitioningGesture(gesture: UIPanGestureRecognizer) {
        guard let toView = self.toViewController?.view, self.isEnableInteractiveDismiss else {
            return
        }
        switch gesture.state {
        case .began:
            self.isInteractiveDismiss = true
            self.interactiveStartingPoint = gesture.location(in: gesture.view)
            self.interactiveStartingSize = toView.bounds.size
            self.startDismiss()
            ((self.fromViewController as? INavigationAnimatorDestination)?.navigationAnimator as? STNavigationAnimator)?.isEnableInteractiveDismiss = false
        case .changed:
            let currentPoint = gesture.location(in: gesture.view)
            let direction = toView.bounds.width
            let currentX = abs(currentPoint.x - self.interactiveStartingPoint.x)
            var progress = currentX / direction
            
            if (currentPoint.x > self.interactiveStartingPoint.x && self.interactiveStartingPoint.x > toView.bounds.width / 2) || (currentPoint.x < self.interactiveStartingPoint.x && self.interactiveStartingPoint.x < toView.bounds.width / 2) {
                progress = 0
            }
            progress = 1 - progress
                        
            self.updateInteractive(progress: progress)
        case .ended:
            
            guard let view = gesture.view else {
                self.cancelInteractive()
                return
            }
            
            let velocity = gesture.velocity(in: gesture.view)
            let center = view.bounds.width / 2
            let dismiss = velocity.x == .zero ? (self.interactiveTransition > 0.5) : (self.interactiveStartingPoint.x < center ? velocity.x > 0 : velocity.x < 0)
            
            if dismiss {
                self.dismisInteractive()
            } else {
                self.cancelInteractive()
            }
        default:
            self.cancelInteractive()
            break
        }
    }
    
    private func updateInteractive(progress: CGFloat) {
        let progressMinValue: CGFloat = 0.75
        self.updateInteractiveTransition(progress: progress, progressMinValue: progressMinValue)
        let progress = max(progressMinValue, progress)
        self.controllerBackgroundView?.transform = CGAffineTransform(scaleX: progress, y: progress)
        self.backroundBlurEffectViewView?.alpha = self.blurEffectViewMinAlpha + progress * (self.blurEffectViewMaxAlpha - self.blurEffectViewMinAlpha)
        self.transitionContext?.updateInteractiveTransition(progress)
    }
    
    private func updateInteractiveTransition(progress: CGFloat, progressMinValue: CGFloat) {
        let progresss = progress - progressMinValue
        let progresssInterval = 1 - progressMinValue
        var progresssCurrent = progresss / progresssInterval
        
        progresssCurrent = max(0, progresssCurrent)
        progresssCurrent = min(1, progresssCurrent)
        self.interactiveTransition = progresssCurrent
        self.transitionContext?.updateInteractiveTransition(self.interactiveTransition)
    }
    
    private func dismisInteractive() {
        self.isAnimated = true
        guard let transitionContext = self.transitionContext else {
            return
        }
        UIView.animate(withDuration: self.animateTime, animations: {
            self.dismissAnimation(containerView: transitionContext.containerView)
            transitionContext.updateInteractiveTransition(1)
            self.interactiveTransition = 1
        }) { (_) in
            transitionContext.finishInteractiveTransition()
            self.isInteractiveDismiss = false
            self.isAnimated = false
            ((self.fromViewController as? INavigationAnimatorDestination)?.navigationAnimator as? STNavigationAnimator)?.isEnableInteractiveDismiss = true
            self.dismissEndAnimation(transitionContext: transitionContext)
        }
    }
    
    private func cancelInteractive() {
        guard let transitionContext = self.transitionContext else {
            return
        }
        UIView.animate(withDuration: self.animateTime, animations: {
            self.controllerBackgroundView?.transform = .identity
            self.backroundBlurEffectViewView?.alpha = self.blurEffectViewMaxAlpha
            self.interactiveTransition = 0
            transitionContext.updateInteractiveTransition(0)
        }) { (_) in
            self.presentEndAnimation(transitionContext: transitionContext, isCompleted: false)
            transitionContext.cancelInteractiveTransition()
            self.isInteractiveDismiss = false
            ((self.fromViewController as? INavigationAnimatorDestination)?.navigationAnimator as? STNavigationAnimator)?.isEnableInteractiveDismiss = true
        }
    }
    
}

extension STNavigationAnimator: INavigationAnimator {
        
    func setupTransitioning(for navigationController: UINavigationController, viewController: INavigationAnimatorDestination) {
        navigationController.delegate = self
    }
    
    func setupTransitioning(for viewController: INavigationAnimatorDestination) {
        viewController.transitioningDelegate = self
    }
    
    var presentingView: UIView? {
        return self.toViewController?.view
    }
    
    var controllerView: UIView? {
        return self.toViewController?.view
    }
    
    var animatorOperation: AnimatorOperation {
        return self.isPresent ? .present : .dissmis
    }
    
}

extension STNavigationAnimator: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isPresent = true
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isPresent = false
        return self
    }
    
}

extension STNavigationAnimator: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.isPresent || !self.isInteractiveDismiss {
            return nil
        }
        return self
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .none {
            return nil
        }
        
        self.operation = operation
        self.isPresent = operation == .push
        return self
    }
    
}

extension STNavigationAnimator: UIViewControllerInteractiveTransitioning {
    
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        self.prepareDismissCntroller(transitionContext: transitionContext)
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if !self.isInteractiveDismiss {
            return nil
        }
        return self
    }
    
}

extension STNavigationAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if self.isPresent {
            self.presentCntroller(transitionContext: transitionContext)
        } else {
            self.dismissCntroller(transitionContext: transitionContext)
        }
    }
    
}

extension STNavigationAnimator: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.dismissTapGesture {
            if let containerView = self.toViewController?.view {
                let location = gestureRecognizer.location(in: gestureRecognizer.view)
                return !containerView.frame.contains(location)
            }
            return false
        }
        guard self.animatorDestination?.navigationAnimator(shouldBeginInteractive: self) ?? true else {
            return false
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
}
