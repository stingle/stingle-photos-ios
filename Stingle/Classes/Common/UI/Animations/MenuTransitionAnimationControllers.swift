import UIKit

class MenuPresentAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

	fileprivate let backgroundViewTag = 123456
	
	private let originFrame: CGRect
	let interactionController: SwipeInteractionController?
	
	init(originFrame: CGRect, interactionController: SwipeInteractionController?) {
		self.originFrame = originFrame
		self.interactionController = interactionController
	}
	
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.8
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let toVC = transitionContext.viewController(forKey: .to)
			else {
				return
		}
		let containerView = transitionContext.containerView
		let backgroundView = transitionContext.containerView.viewWithTag(backgroundViewTag) ?? UIView(frame: originFrame)
		backgroundView.tag = backgroundViewTag
		backgroundView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
		toVC.view.layer.masksToBounds = true
		containerView.addSubview(backgroundView)
		containerView.addSubview(toVC.view)
		let width = toVC.view.frame.width
		toVC.view.frame.origin.x = -width
		let duration = transitionDuration(using: transitionContext)
		UIView.animateKeyframes(
			withDuration: duration,
			delay: 0,
			options: .calculationModeCubic,
			animations: {
				UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2) {
					backgroundView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)
				}
				UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.8) {
					toVC.view.frame.origin.x = 0
				}
		}) { _ in
				transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		}
	}
}


class MenuDismissAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
	
	private let destinationFrame: CGRect
	let interactionController: SwipeInteractionController?

	init(destinationFrame: CGRect, interactionController: SwipeInteractionController?) {
		self.destinationFrame = destinationFrame
		self.interactionController = interactionController
	}
	
	
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.45
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let vc = transitionContext.viewController(forKey: .from)
			else {
				return
		}
		vc.view.layer.masksToBounds = true
		let originalTransform = vc.view.layer.transform
		let duration = transitionDuration(using: transitionContext)
		let width = vc.view.frame.width
		UIView.animateKeyframes(
			withDuration: duration,
			delay: 0,
			options: .calculationModeCubic,
			animations: {
				UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
					vc.view.frame.origin.x =  -width
				}
		},
			completion: { _ in
				vc.view.removeFromSuperview()
				vc.view.layer.transform = originalTransform
				transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		})
	}
}

