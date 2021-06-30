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
    @IBOutlet weak private var playerControllBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak private var imageView: STImageView!
   
    @IBOutlet weak private var loadingView: UIActivityIndicatorView!
    @IBOutlet weak private var playButton: UIButton!
    
    @IBOutlet weak private var timeLeftLabel: UILabel!
    @IBOutlet weak private var timeRightLabel: UILabel!
    
    private(set) var videoFile: STLibrary.File!
    private(set) var fileIndex: Int = .zero
    weak var fileViewerDelegate: IFileViewerDelegate?
    private let player = STPlayer()
        
    @IBAction func sliderDidChange(_ sender: Any) {
        let time = TimeInterval(self.slider.value) * self.player.duration
        self.player.seek(currentTime: time)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setImage()
        self.loadingView.color = (self.fileViewerDelegate?.isFullScreenMode ?? false) ? .white : .appText
        self.playerControllView.alpha = (self.fileViewerDelegate?.isFullScreenMode ?? false) ? .zero : 1
        self.playerControllBottomConstraint.constant = self.tabBarController?.tabBar.frame.height ?? .zero
        self.videoView.setPlayer(player: self.player)
        self.player.play(file: self.file)
        self.player.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player.pause()
    }
    
    //MARK: - User action
    
    @IBAction func didSelectPlayButton(_ sender: Any) {
        
    }
    
    @IBAction func didSelectBackwardButton(_ sender: Any) {
        
    }
    
    @IBAction func didSelectForwardButton(_ sender: Any) {
        
    }
    
    //MARK: - Private methods
    
    private func setImage() {
        let thumb = STImageView.Image(file: self.videoFile, isThumb: true)
        self.imageView.setImage(source: thumb)
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
        self.playerControllBottomConstraint.constant = self.tabBarController?.tabBar.frame.height ?? .zero
        self.loadingView.color = (self.fileViewerDelegate?.isFullScreenMode ?? false) ? .white : .appText
    }

}
