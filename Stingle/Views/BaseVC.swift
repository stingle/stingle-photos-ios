import UIKit

class BaseVC: UIViewController {
	
	let screenWidth = UIScreen.main.bounds.size.width
	let screenHeight = UIScreen.main.bounds.size.height
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if #available(iOS 13.0, *) {
			let app = UIApplication.shared
			let statusBarHeight: CGFloat = app.statusBarFrame.size.height
			let statusbarView = UIView()
			statusbarView.backgroundColor = Theme.Colors.SPDarkRed
			view.addSubview(statusbarView)
			statusbarView.translatesAutoresizingMaskIntoConstraints = false
			statusbarView.heightAnchor
				.constraint(equalToConstant: statusBarHeight).isActive = true
			statusbarView.widthAnchor
				.constraint(equalTo: view.widthAnchor, multiplier: 1.0).isActive = true
			statusbarView.topAnchor
				.constraint(equalTo: view.topAnchor).isActive = true
			statusbarView.centerXAnchor
				.constraint(equalTo: view.centerXAnchor).isActive = true
		} else {
			let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
			statusBar?.backgroundColor = Theme.Colors.SPDarkRed
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
	
	func viewController(with name:String, from scene:String) -> BaseVC? {
		guard Thread.current.isMainThread else {
			fatalError()
		}
		var viewController:BaseVC? = nil
		viewController = UIStoryboard(name:scene, bundle: nil).instantiateViewController(withIdentifier: name) as? BaseVC
		return viewController
	}
}
