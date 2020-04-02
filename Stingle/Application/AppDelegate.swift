
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
		if User.get() != nil {
			openHomeScene()
		} else {
			openWelcomeScene()
		}
		
        return true
    }
	
	private func openWelcomeScene() {
        let storyboard = UIStoryboard.init(name: "Welcome", bundle: nil)
        let welcome = storyboard.instantiateInitialViewController()
		let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
		window?.rootViewController = welcome
		window?.makeKeyAndVisible()
		
    }
    
	private func openHomeScene() {
        let storyboard = UIStoryboard.init(name: "Home", bundle: nil)
        let home = storyboard.instantiateInitialViewController()
		let window:UIWindow? = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
		window?.rootViewController = home
		window?.makeKeyAndVisible()
    }
}

