import UIKit

class BaseVC: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
	
	func viewController(with name:String, from scene:String) -> UIViewController? {
		guard Thread.current.isMainThread else {
			fatalError()
		}
		let viewController:UIViewController? = UIStoryboard(name:scene, bundle: nil).instantiateViewController(withIdentifier: name)
		return viewController
	}
}
