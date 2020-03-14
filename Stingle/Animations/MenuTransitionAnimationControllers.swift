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
		return 0.6
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let toVC = transitionContext.viewController(forKey: .to)
			else {
				return
		}
		let containerView = transitionContext.containerView
		let backgroundView = transitionContext.containerView.viewWithTag(backgroundViewTag) ?? UIView(frame: originFrame)
		backgroundView.tag = backgroundViewTag
		backgroundView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)

		
		toVC.view.layer.masksToBounds = true
		let originalTransform = toVC.view.layer.transform
		containerView.addSubview(backgroundView)
		containerView.addSubview(toVC.view)
		
		
		let duration = transitionDuration(using: transitionContext)
		let width = toVC.view.frame.width
		let initialTransform = CATransform3DTranslate(originalTransform, -width, 0.0, 0.0)
		toVC.view.layer.transform = initialTransform
		UIView.animateKeyframes(
			withDuration: duration,
			delay: 0,
			options: .calculationModeCubic,
			animations: {
				
				UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
					toVC.view.layer.transform = CATransform3DTranslate(initialTransform, width, 0.0, 0.0)
				}
				
		},
			completion: { _ in
				transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		})
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
					vc.view.layer.transform = CATransform3DTranslate(originalTransform, -width, 0.0, 0.0)
				}
				
		},
			completion: { _ in
				vc.view.removeFromSuperview()
				vc.view.layer.transform = originalTransform
				transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		})
	}
	
	
}

