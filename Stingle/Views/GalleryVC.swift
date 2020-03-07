import UIKit

class GalleryVC : BaseVC, GalleryDelegate {
	
	@IBOutlet weak var count: UILabel!
	var viewModel:GalleryVM?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		count.text = "0"
		viewModel = GalleryVM()
		viewModel?.delegate = self
	}
	
	static var count  = 0
	
	func gallery(items:[String]) {
		GalleryVC.count += 1
		count.text = "\(GalleryVC.count)"
	}
	
}
