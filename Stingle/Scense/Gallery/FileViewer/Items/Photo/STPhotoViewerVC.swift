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
    private(set) var photoFile: STLibrary.FileBase!
    
    private var isThumbSeted = false
    private var isViewDidAppear = false
    
    var fileIndex: Int = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.zoomImageView.delegate = self
        self.setImage(isThumb: true) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.isThumbSeted = true
            if weakSelf.isViewDidAppear {
                weakSelf.setImage(isThumb: false) { }
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !self.isViewDidAppear else {
            return
        }
        
        self.isViewDidAppear = true
        if self.isThumbSeted {
            self.setImage(isThumb: false) { }
        }
    }

    //MARK: - Private
    
    private func setImage(isThumb: Bool, complition: @escaping (() -> Void)) {
        self.loadingView.startAnimating()
        let source = STImageView.Image(file: self.photoFile, isThumb: isThumb)
        self.zoomImageView.imageView.setImage(source: source, success: { [weak self] _ in
            self?.loadingView.stopAnimating()
            complition()
        }, progress: nil, failure: { [weak self] _ in
            self?.loadingView.stopAnimating()
            complition()
        }, saveOldImage: true)
    }

}

extension STPhotoViewerVC: IFileViewer {

    static func create(file: STLibrary.FileBase, fileIndex: Int) -> IFileViewer {
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: STPhotoViewerVC = storyboard.instantiateViewController(identifier: "STPhotoViewerVCID")
        vc.photoFile = file
        vc.fileIndex = fileIndex
        return vc
    }
    
    var file: STLibrary.FileBase {
        return self.photoFile
    }
    
    var animatorSourceView: INavigationAnimatorSourceView? {
        return self.zoomImageView
    }
    
    func fileViewer(didChangeViewerStyle fileViewer: STFileViewerVC, isFullScreen: Bool) {
        self.loadingView.color = (self.fileViewerDelegate?.isFullScreenMode ?? false) ? .white : .appText
    }
    
    func fileViewer(pauseContent fileViewer: STFileViewerVC) {}

    func reload(file: STLibrary.FileBase, fileIndex: Int) {
        self.fileIndex = fileIndex
        self.photoFile = file
        guard self.isViewLoaded else {
            return
        }
        self.setImage(isThumb: false, complition: {})
    }

    func reload(fileIndex: Int) {
        self.fileIndex = fileIndex
    }

}

extension STPhotoViewerVC: STImageZoomViewDelegate {
    
    func zoomViewDidZoom(_ zoomView: STImageZoomView) {
        self.fileViewerDelegate?.photoViewer(startFullScreen: self)
    }
        
}
