import UIKit
import StingleRoot

class STLandingVC: UIViewController {
	
	private let viewModel = STLandingVM()
	
	@IBOutlet weak private var signUpButton: UIButton!
	@IBOutlet weak private var signInButton: UIButton!
	@IBOutlet weak private var alreadyHaveAnAccountLabel: UILabel!
    @IBOutlet weak var appServerButton: STButton!
    
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configure()
	}
		
	override func isNavigationBarHidden() -> Bool {
		return true
	}
	
	//MARK: - Private func
	
    @IBAction func didSelectAppServerButton(_ sender: Any) {
        let alert = UIAlertController(title: "change_app_server_url".localized, message: nil, preferredStyle: .alert)
        
        let url = self.viewModel.getAppServer()
        alert.addTextField { field in
            field.placeholder = "app_server".localized
            field.text = url
        }
        
        alert.addAction(UIAlertAction(title: "done".localized, style: .default, handler: { [weak self] _ in
            do {
                try self?.viewModel.setAppServer(url: alert.textFields?.first?.text)
            } catch {
                self?.showError(error: error)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "set_default".localized, style: .default, handler: { [weak self] _ in
            self?.viewModel.setAppServerDefault()
        }))
        
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel))
        self.showDetailViewController(alert, sender: nil)
    }
    
    private func configure() {
        self.appServerButton.setTitle("app_server".localized, for: .normal)
		self.signInButton.titleLabel?.attributedText = self.viewModel.signInTitle()
        self.signInButton.setTitleColor(UIColor.appPrimary, for: UIControl.State.normal)
		self.signUpButton.titleLabel?.attributedText = self.viewModel.signUpTitle()
		self.alreadyHaveAnAccountLabel?.attributedText = self.viewModel.haveAnAccountTitle()
	}
	
}
