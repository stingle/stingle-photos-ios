import UIKit

class LandingVC: BaseVC {
	
	let viewModel:LandingVM = LandingVM()
	
	@IBOutlet weak var signUp: UIButton!
	@IBOutlet weak var signIn: UIButton!
	@IBOutlet weak var alreadyHaveAnAccount: UILabel!
		
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        guard let navigationController = self.navigationController else {
            return
        }
        navigationController.setNavigationBarHidden(true, animated: false)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		signIn.titleLabel?.attributedText = viewModel.signInTitle()
		signIn.setTitleColor(Theme.Colors.SPRed, for: UIControl.State.normal)
		signIn.backgroundColor = UIColor.clear

		signUp.titleLabel?.attributedText = viewModel.signUpTitle()
		signUp.setTitleColor(UIColor.white, for: UIControl.State.normal)
		signUp.backgroundColor = Theme.Colors.SPRed

		alreadyHaveAnAccount?.attributedText = viewModel.haveAnAccountTitle()
	}
}
