import UIKit

class STLandingVC: UIViewController {
	
	private let viewModel = STLandingVM()
	
	@IBOutlet weak private var signUpButton: UIButton!
	@IBOutlet weak private var signInButton: UIButton!
	@IBOutlet weak private var alreadyHaveAnAccountLabel: UILabel!

	override func viewDidLoad() {
		super.viewDidLoad()
		self.configure()
	}
		
	override func isNavigationBarHidden() -> Bool {
		return true
	}
	
	//MARK: - Private func
	
	private func configure() {
		self.signInButton.titleLabel?.attributedText = self.viewModel.signInTitle()
        self.signInButton.setTitleColor(UIColor.appPrimary, for: UIControl.State.normal)
		self.signUpButton.titleLabel?.attributedText = self.viewModel.signUpTitle()
		self.alreadyHaveAnAccountLabel?.attributedText = self.viewModel.haveAnAccountTitle()
	}
	
}
