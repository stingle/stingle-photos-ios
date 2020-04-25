
import UIKit

class SPImagePreviewVC: UIViewController, SPEventHandler {
	@IBAction func back(_ sender: Any) {
		self.navigationController?.popViewController(animated: true)
	}
	
	@IBAction func share(_ sender: Any) {
		print("share")
		let items = ["This app is my favorite"]
		let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
		present(ac, animated: true)
	}
	
	@IBAction func deleteItem(_ sender: Any) {
		print("delete")
	}
	
	var index:Int = NSNotFound
	public var dataSource:DataSource? = nil
	var viewModel:SPImagePreviewVM? = nil

	let db = SyncManager.db
	
	@IBOutlet weak var imageView: UIImageView!
	
	private var statusBar:UIView? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		let screenSize: CGRect = UIScreen.main.bounds
		let width = screenSize.size.width
		imageView.image = viewModel?.thumb(for: index)?.scale(to: width)
		
		// Do any additional setup after loading the view.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(true, animated: false)
//		if #available(iOS 13.0, *) {
//			 UIApplication.shared.keyWindow?.addSubview(statusBar!)
//		}
//
//		statusBar?.backgroundColor = .darkGray
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		imageView.enableZoom()
		viewModel?.image(for: index, completionHandler: { (image) in
			print("image downloaded")
			self.imageView?.image = image
		})
		
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
//		if #available(iOS 13.0, *) {
//			statusBar?.removeFromSuperview()
//			statusBar?.backgroundColor = Theme.Colors.SPDarkRed
//		}
	}
	
	func recieve(event: SPEvent) {
		guard let info = event.info else {
			return
		}
		switch event.type {
		case SPEvent.UI.ready.image.rawValue:
			guard let indexes = info[SPEvent.Keys.Indexes.rawValue] as! [Int]? else {
				return
			}
			break
		default:
			return
		}
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
