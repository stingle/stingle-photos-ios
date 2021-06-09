//
//  STVodeoViewerVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import UIKit

class STVodeoViewerVC: UIViewController {

    @IBOutlet weak var videoView: STVideoView!
    
    private(set) var videoFile: STLibrary.File!
    @IBOutlet weak var slider: UISlider!
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

extension STVodeoViewerVC: IFileViewer {

    static func create(file: STLibrary.File) -> IFileViewer {
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: STVodeoViewerVC = storyboard.instantiateViewController(identifier: "STVodeoViewerVCID")
        vc.videoFile = file
        return vc
    }
    
    var file: STLibrary.File {
        return self.videoFile
    }

    
}
