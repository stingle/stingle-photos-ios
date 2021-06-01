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
    private let player = STPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoView.setPlayer(player: self.player)
        self.player.play(file: self.file)
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
