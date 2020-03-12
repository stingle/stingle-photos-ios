
import UIKit

class HomeVC: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationBarHidden(true, animated: false)

		let galleryVC = UIStoryboard(name:"Home", bundle: nil).instantiateViewController(withIdentifier: "GalleryVC")  as! GalleryVC
		let rootController = RootViewController(mainViewController: galleryVC, topNavigationLeftImage: UIImage(named: "menu"))
		let menuVC = UIStoryboard(name:"Home", bundle: nil).instantiateViewController(withIdentifier: "SPMenuVC") as! SPMenuVC
		menuVC.view.backgroundColor = .white
		
		let drawerVC = DrawerController(rootViewController: rootController, menuController: menuVC)
		self.addChild(drawerVC)
		view.addSubview(drawerVC.view)
		drawerVC.didMove(toParent: self)

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
