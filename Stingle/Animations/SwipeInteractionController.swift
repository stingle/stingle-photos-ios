
import UIKit

class SwipeInteractionController : UIPercentDrivenInteractiveTransition {
	var interactionInProgress = false
	
	private var shouldCompleteTransition = false
	private weak var viewController: UIViewController!
	private var maxTransition:CGFloat?
	
	init(viewController: UIViewController, maxTransition:CGFloat = 200) {
		super.init()
		self.viewController = viewController
		self.maxTransition = maxTransition
		prepareGestureRecognizer(in: viewController.view)
	}
	
	private func prepareGestureRecognizer(in view: UIView) {
		let panGsture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
		view.addGestureRecognizer(panGsture)
	}
	
	@objc func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
		// 1
		let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
		var progress = (translation.x / maxTransition!)
		progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
		
		switch gestureRecognizer.state {
			
		// 2
		case .began:
			interactionInProgress = true
			
		// 3
		case .changed:
			shouldCompleteTransition = progress > 0.01
			update(progress)
			
		// 4
		case .cancelled:
			interactionInProgress = false
			cancel()
			
		// 5
		case .ended:
			interactionInProgress = false
			if shouldCompleteTransition {
				finish()
			} else {
				cancel()
			}
		default:
			break
		}
	}
	
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 2.0
	}
	
}

extension SwipeInteractionController : UIViewControllerTransitioningDelegate {
	
}


