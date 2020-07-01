import UIKit
import MobileVLCKit

class SPVideoPreview : UIViewController {
	
	var index:Int = NSNotFound
	var viewModel:SPMediaPreviewVM? = nil
	
	@IBOutlet weak var play: UIButton!
	@IBOutlet weak var videoLayer: UIView!
	var mediaPlayer = VLCMediaPlayer.init()
	var file:SPFileInfo? = nil
	
	@IBAction func playVideo(_ sender: Any) {
		if mediaPlayer.isPlaying {
			mediaPlayer.pause()
		}
		mediaPlayer.play()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let source:SPFileSource = SPFileSource(file: file!)
		mediaPlayer.delegate = self;
		mediaPlayer.drawable = self.view;
		mediaPlayer.media = VLCMedia.init(source: source)
	}
}

extension SPVideoPreview : VLCMediaPlayerDelegate {
}

