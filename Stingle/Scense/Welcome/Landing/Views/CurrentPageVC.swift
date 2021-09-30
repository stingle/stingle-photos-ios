import UIKit

class CurrentPageVC: UIViewController {

	let viewModel = STLandingVM()
	var index:Int = NSNotFound
	
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var descriptionTitle: UILabel!
	@IBOutlet weak var desc: UILabel!
		
    override func viewDidLoad() {
        super.viewDidLoad()
		viewModel.page = index
		image.image = viewModel.image()
		desc.attributedText = viewModel.description()
		descriptionTitle.attributedText = viewModel.descriptionTitle()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
}
