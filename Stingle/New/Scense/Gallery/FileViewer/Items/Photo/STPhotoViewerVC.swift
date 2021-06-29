//
//  STPhotoViewerVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import UIKit

protocol STPhotoViewerVCDelegate: AnyObject {
   
    func photoViewer(startFullScreen viewer: STPhotoViewerVC)
    
}

class STPhotoViewerVC: UIViewController {
    
    @IBOutlet weak private var zoomImageView: STImageZoomView!
    
    weak var delegate: STPhotoViewerVCDelegate?
    private(set) var photoFile: STLibrary.File!
    private(set) var fileIndex: Int = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadImage()
    }
    
    private func reloadImage() {
        let thumb = STImageView.Image(file: self.photoFile, isThumb: true)
        let original = STImageView.Image(file: self.photoFile, isThumb: false)
        let image = STImageView.Images(thumb: thumb, original: original)
        self.zoomImageView.delegate = self
        self.zoomImageView.imageView.setImage(image)
    }

}

extension STPhotoViewerVC: IFileViewer {

    static func create(file: STLibrary.File, fileIndex: Int) -> IFileViewer {
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: STPhotoViewerVC = storyboard.instantiateViewController(identifier: "STPhotoViewerVCID")
        vc.photoFile = file
        vc.fileIndex = fileIndex
        return vc
    }
    
    var file: STLibrary.File {
        return self.photoFile
    }

}

extension STPhotoViewerVC: STImageZoomViewDelegate {
    
    func zoomViewDidZoom(_ zoomView: STImageZoomView) {
        self.delegate?.photoViewer(startFullScreen: self)
    }
        
}
