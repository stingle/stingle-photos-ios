import UIKit

class SignInVC : BaseVC {
	
	private let viewModel = SignInVM()
	
	@IBOutlet weak var emailInput: UITextField!
	@IBOutlet weak var emailSeparattor: UIView!
	@IBOutlet weak var passwordInput: UITextField!
	@IBOutlet weak var passwordSeparattor: UIView!
	@IBOutlet weak var forgotPassword: UIButton!
	@IBOutlet weak var signIn: UIButton!
	@IBOutlet weak var signUp: UIButton!
	@IBOutlet weak var dontHaveAnAccount: UILabel!
	
	@IBAction func singInClicked(_ sender: Any) {
		_ = viewModel.signIn(email: "grig.davit@gmail.com", password: "mekicvec" ) { (status, error) in
			do {
				if status {
					_ = DataSource.update(completionHandler: { (status) in
						if status == true {
							DispatchQueue.main.async {
								let storyboard = UIStoryboard.init(name: "Home", bundle: nil)
								let home = storyboard.instantiateInitialViewController()
								self.navigationController?.pushViewController(home!, animated: false)
							}
						}
					})
				}
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		createBackBarButton(forNavigationItem: self.navigationItem)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		guard let navigationController = self.navigationController else {
			return
		}
		navigationController.setNavigationBarHidden(false, animated: false)
	}
	
	//TODO : create reusable components (with style ) such as navigation bar, navigation bar items ... 
	func createBackBarButton(forNavigationItem navigationItem:UINavigationItem) {
		let backButtonImage = UIImage(named: "arrow_back")
		let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: backButtonImage!.size.width, height: backButtonImage!.size.height))
		backButton.setImage(backButtonImage!, for: .normal)
		backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
		let backBarButton = UIBarButtonItem(customView: backButton)
		let spaceBar = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
		spaceBar.width = 30
		let titleLabel = UILabel()
		let text = "landing_sign_in".localized
		let string = NSMutableAttributedString(string: text)
		string.setFont(font: Theme.Fonts.SFProMedium(size: 20), forText: text)
		string.setColor(color: .white, forText: text)
		titleLabel.attributedText = string
		let titleBar = UIBarButtonItem(customView: titleLabel)
		navigationItem.leftBarButtonItems = [backBarButton, spaceBar, titleBar]
	}
	
	@objc public func backButtonTapped() {
		self.navigationController?.popToRootViewController(animated: true)
	}
}
