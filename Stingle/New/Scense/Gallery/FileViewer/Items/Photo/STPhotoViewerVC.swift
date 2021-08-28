//
//  STPhotoViewerVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import UIKit

class STPhotoViewerVC: UIViewController {
    
    @IBOutlet weak private var zoomImageView: STImageZoomView!
    @IBOutlet weak private var loadingView: UIActivityIndicatorView!
    
    weak var fileViewerDelegate: IFileViewerDelegate?
    private(set) var photoFile: STLibrary.File!
    private(set) var fileIndex: Int = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.zoomImageView.delegate = self
        let thumb = STImageView.Image(file: self.photoFile, isThumb: true)
        self.zoomImageView.imageView.setImage(source: thumb, saveOldImage: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadingView.startAnimating()
        let image = STImageView.Image(file: self.photoFile, isThumb: false)
        self.zoomImageView.imageView.setImage(source: image, placeholder: nil, animator: nil, success: { [weak self] _ in
            self?.loadingView.stopAnimating()
        }, progress: nil, failure: { [weak self] _ in
            self?.loadingView.stopAnimating()
        }, saveOldImage: true)
        
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
    
    func fileViewer(didChangeViewerStyle fileViewer: STFileViewerVC, isFullScreen: Bool) {
        self.loadingView.color = (self.fileViewerDelegate?.isFullScreenMode ?? false) ? .white : .appText
    }
    
    func fileViewer(pauseContent fileViewer: STFileViewerVC) {}

}

extension STPhotoViewerVC: STImageZoomViewDelegate {
    
    func zoomViewDidZoom(_ zoomView: STImageZoomView) {
        self.fileViewerDelegate?.photoViewer(startFullScreen: self)
    }
        
}
