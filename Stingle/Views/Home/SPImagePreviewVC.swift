
import UIKit

class SPImagePreviewVC: UIViewController, SPEventHandler {
	
	
	var index:Int = NSNotFound
	public var dataSource:DataSource? = nil
	var viewModel:SPImagePreviewVM? = nil

	let db = SyncManager.db
	
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var scrollView: UIScrollView!

	private var statusBar:UIView? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		scrollView.delegate = self
		let screenSize: CGRect = UIScreen.main.bounds
		let width = screenSize.size.width
		imageView.image = viewModel?.thumb(for: index)?.scale(to: width)
		
		// Do any additional setup after loading the view.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		viewModel?.image(for: index, completionHandler: { (image) in
			print("image downloaded")
			self.imageView?.image = image
		})
		
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
	
	
	@objc func backToGallery(_ sender: Any) {
		navigationController?.popViewController(animated: true)
	}

	@objc func deleteImage(_ sender: Any) {
	}
	
	@objc func share(_ sender: Any) {
		guard let image = imageView.image else {
			return
		}
		let items = [image]
		let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
		present(ac, animated: true)
	}

	
	func recieve(event: SPEvent) {
//		guard let info = event.info else {
//			return
//		}
		switch event.type {
		case SPEvent.UI.ready.image.rawValue:
//			guard let indexes = info[SPEvent.Keys.Indexes.rawValue] as! [Int]? else {
//				return
//			}
			break
		default:
			return
		}
	}
}

extension SPImagePreviewVC : UIScrollViewDelegate {
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}
	
	@objc func startZooming(_ sender: UIPinchGestureRecognizer) {
		let scaleResult = sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale)
		guard let scale = scaleResult, scale.a > 1, scale.d > 1 else { return }
		sender.view?.transform = scale
		sender.scale = 1
		print(scrollView.bounds.size.width, scrollView.contentSize.width)
	}
	
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		let size = imageView!.frame.size
		scrollView.contentSize =  CGSize(width: size.width, height: size.height)
		let offsetX = max((scrollView.contentSize.width - scrollView.bounds.size.width) * 0.5, 0.0)
		let offsetY = max((scrollView.contentSize.height - scrollView.bounds.size.height) * 0.5, 0.0)
		scrollView.contentOffset = CGPoint(x:offsetX, y:offsetY)
		print(scrollView.bounds.size, scrollView.contentSize.width, scrollView.contentSize.height )
	}

	}
