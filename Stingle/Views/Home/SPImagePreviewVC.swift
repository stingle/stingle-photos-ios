
import UIKit

class SPImagePreviewVC: BaseVC {
	
	var index:Int = NSNotFound
	
	var image:UIImage?
	
	@IBOutlet weak var imageView: UIImageView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		imageView.image = image
        // Do any additional setup after loading the view.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		imageView.enableZoom()
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
