import UIKit
import MobileVLCKit

class SPVideoPreviewVC : SPMediaPreviewVC {
	
	var file:SPFileInfo?
	
	var hideControls:Bool = true
	
	@IBOutlet weak var timePlayed: UILabel!
	@IBOutlet weak var timeLeft: UILabel!
	
	@IBOutlet weak var videoProgress: UISlider!
	@IBOutlet weak var play: UIButton!
	@IBOutlet weak var videoLayer: UIView!
	
	private var mediaPlayer = VLCMediaPlayer.init()
	private var source:SPFileSource? = nil
	
	private var offset:UInt64 = 0
	
	@IBAction func playVideo(_ sender: Any) {
		playPause()
	}

	@IBAction func valueChanged(_ sender: Any) {
		let value = (sender as! UISlider).value
		print(mediaPlayer.position)
		mediaPlayer.position = value
		print(mediaPlayer.position)
	}
	
	
	func playPause() {
		if mediaPlayer.isPlaying {
			mediaPlayer.pause()
			play.setImage(UIImage(named: "play.fill"), for: .normal)
		} else {
			mediaPlayer.play()
			play.setImage(UIImage(named: "pause.fill"), for: .normal)
		}
	}
	
	@objc func showHideControls() {
		UIView.animate(withDuration: 0.3) {
			self.play.alpha = self.hideControls ? 0 : 1
			self.timeLeft.alpha = self.hideControls ? 0 : 1
			self.timePlayed.alpha = self.hideControls ? 0 : 1
			self.videoProgress.alpha = self.hideControls ? 0 : 1

			self.hideControls = !self.hideControls
		}
	}
	
	override func viewDidLoad() {
		let tap = UITapGestureRecognizer(target: self, action: #selector(showHideControls))
		self.view.addGestureRecognizer(tap)
		
		super.viewDidLoad()
		file = viewModel?.file(for: index)
		guard let file = file else {
			return
		}
		timeLeft.text = "00:\(file.duration())"
		timePlayed.text = "00:00"
		mediaPlayer.addObserver(self, forKeyPath: "position", options: .new, context: nil)
		if let file = viewModel?.file(for: index) {
			source = SPFileSource(file: file)
			if let src = source {
				mediaPlayer.delegate = self
				mediaPlayer.drawable = self.videoLayer
				let media = VLCMedia.init(source: src)
				mediaPlayer.media = media
			}
		}
	}
		
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		mediaPlayer.stop()
	}
		
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let file = file else {
			return
		}
		videoProgress.value = change![.newKey] as! Float
		let time = UInt32(mediaPlayer.position * Float(file.duration()))
		timeLeft.text = timeString(time:file.duration() - time)
		timePlayed.text = timeString(time:time)
	}
	
	func timeString(time:UInt32) -> String {
		var res:String = ""
		let min:UInt32 = time / 60
		if min < 10 {
			res += "0\(min)"
		} else {
			res += "\(min)"
		}
		res += ":"
		let sec:UInt32 = time % 60
		if sec < 10 {
			res += "0\(sec)"
		} else {
			res += "\(sec)"
		}

		return res
	}

}

extension SPVideoPreviewVC : VLCMediaPlayerDelegate {
}
