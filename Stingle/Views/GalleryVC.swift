import UIKit

class GalleryVC : BaseVC {
	let viewModel = GalleryVM()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		viewModel.update(lastSeen: "0", lastDelSeen: "0")
		}
}
