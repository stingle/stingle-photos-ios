import UIKit

class BaseVC: UIViewController {
	
	let screenWidth = UIScreen.main.bounds.size.width
	let screenHeight = UIScreen.main.bounds.size.height
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if #available(iOS 13.0, *) {
			let statusBar = UIView(frame: UIApplication.shared.keyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
			 statusBar.backgroundColor = Theme.Colors.SPDarkRed
			 UIApplication.shared.keyWindow?.addSubview(statusBar)
		} else {
			let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
			statusBar?.backgroundColor = Theme.Colors.SPDarkRed
		}
		if let navigationController = self.navigationController {
			navigationController.navigationBar.barTintColor = Theme.Colors.SPRed
		}
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
