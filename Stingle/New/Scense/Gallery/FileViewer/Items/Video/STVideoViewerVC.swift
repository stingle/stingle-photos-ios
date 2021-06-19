//
//  STVodeoViewerVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import UIKit

class STVideoViewerVC: UIViewController {

    @IBOutlet weak var videoView: STVideoView!
    @IBOutlet weak var slider: UISlider!
    
    private(set) var videoFile: STLibrary.File!
    private(set) var fileIndex: Int = .zero
    
    private let player = STPlayer()
    
    
    
    @IBAction func sliderDidChange(_ sender: Any) {
        let time = TimeInterval(self.slider.value) * self.player.duration
        self.player.seek(currentTime: time)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoView.setPlayer(player: self.player)
        self.player.play(file: self.file)
        self.player.play()
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

}
