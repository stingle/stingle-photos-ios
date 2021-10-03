//
//  STVodeoViewerVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import UIKit

class STVideoViewerVC: UIViewController {

    @IBOutlet weak private var videoView: STVideoView!
    @IBOutlet weak private var slider: UISlider!
    @IBOutlet weak private var playerControllView: STGradientView!
    @IBOutlet weak private var imageView: STImageView!
   
    @IBOutlet weak private var loadingView: UIActivityIndicatorView!
    @IBOutlet weak private var loadingBgView: UIView!
    @IBOutlet weak private var playButton: UIButton!
    
    @IBOutlet weak private var timeLeftLabel: UILabel!
    @IBOutlet weak private var timeRightLabel: UILabel!
    
    private(set) var videoFile: STLibrary.File!
    private(set) var fileIndex: Int = .zero
    private var isSliding = false
    private let player = STPlayer()
    
    private let playerSeekTime: TimeInterval = 15
    
    weak var fileViewerDelegate: IFileViewerDelegate?
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
       
    override func viewDidLoad() {
        super.viewDidLoad()
        self.slider.value = .zero
        self.loadingBgView.alpha = .zero
        self.player.addObserver(deleagte: self)
        self.setImage()
        self.playerControllView.alpha = (self.fileViewerDelegate?.isFullScreenMode ?? false) ? .zero : 1
        self.videoView.setPlayer(player: self.player)
        self.player.replaceCurrentItem(with: self.file)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player.pause()
    }
    
    //MARK: - User action
    
    @IBAction func didSelectPlayButton(_ sender: Any) {
        if self.playButton.isSelected {
            self.player.pause()
        } else {
            self.player.play()
        }
    }
    
    @IBAction func didSelectBackwardButton(_ sender: Any) {
        let time = self.player.currentTime
        var seekTime = min(time - self.playerSeekTime, self.player.duration)
        seekTime = max(seekTime, .zero)
        self.player.seek(currentTime: seekTime)
    }
    
    @IBAction func didSelectForwardButton(_ sender: Any) {
        let time = self.player.currentTime
        var seekTime = min(time + self.playerSeekTime, self.player.duration)
        seekTime = max(seekTime, .zero)
        self.player.seek(currentTime: seekTime)
    }
    
    @IBAction private func sliderDidChange(_ sender: UISlider, forEvent: UIEvent) {
        guard let touchEvent = forEvent.allTouches?.first else {
            return
        }
        switch touchEvent.phase {
        case .began:
            self.isSliding = true
        case .moved:
            self.didChangedSildeValue()
        default:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                 self?.isSliding = false
            }
            break
        }
    }
    
    //MARK: - Private methods
    
    private func setImage() {
        let thumb = STImageView.Image(file: self.videoFile, isThumb: true)
        self.imageView.setImage(source: thumb)
    }
    
    private func didChangedSildeValue() {
        let time = TimeInterval(self.slider.value) * self.player.duration
        self.player.seek(currentTime: time)
    }
    
    private func stringFromTimeInterval(interval: TimeInterval) -> String {
        let ti = Int(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        if hours > 0 {
            return String(format: "%0.2d:%0.2d:%0.2d%", hours, minutes, seconds)
        }
        return String(format: "%0.2d:%0.2d%", minutes, seconds)
    }
    
    deinit {
        self.player.stop()
    }
    
}

extension STVideoViewerVC: IFileViewer {
   
    static func create(file: STLibrary.File, fileIndex: Int) -> IFileViewer {
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: STVideoViewerVC = storyboard.instantiateViewController(identifier: "STVodeoViewerVCID")
        vc.videoFile = file
        vc.fileIndex = fileIndex
        return vc
    }

    var file: STLibrary.File {
        return self.videoFile
    }
    
    func fileViewer(didChangeViewerStyle fileViewer: STFileViewerVC, isFullScreen: Bool) {
        self.playerControllView.alpha = isFullScreen ? .zero : 1
    }
    
    func fileViewer(pauseContent fileViewer: STFileViewerVC) {
        self.player.pause()
    }

}

extension STVideoViewerVC: IPlayerObservers {
    
    func player(player: STPlayer, didChangeFirstLoaded: Bool) {
        self.updateSlider()
        self.updateTimeLabels()
    }
    
    func player(player: STPlayer, didChange status: STPlayer.Status) {
        if status == .buffering {
            self.loadingBgView.alpha = 1
            self.loadingView.startAnimating()
        } else {
            self.loadingBgView.alpha = .zero
            self.loadingView.stopAnimating()
        }
    }
    
    func player(player: STPlayer, didChange time: TimeInterval) {
        self.updateSlider()
        self.updateTimeLabels()
    }
    
    func player(player: STPlayer, didChange state: STPlayer.State) {
        self.playButton.isSelected = state == .playing
    }
        
    private func updateSlider() {
        guard !self.isSliding else {
            return
        }
        self.slider.value = self.player.duration != .zero ? Float(self.player.currentTime / self.player.duration) : .zero
    }
    
    
    private func updateTimeLabels() {
        self.timeLeftLabel.text = self.stringFromTimeInterval(interval: self.player.currentTime)
        self.timeRightLabel.text = self.stringFromTimeInterval(interval: self.player.duration)
    }
    
}
