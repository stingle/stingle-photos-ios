//
//  STImageZoomView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 6/23/21.
//

import UIKit

protocol STImageZoomViewDelegate: AnyObject {
    
    func zoomViewDidZoom(_ zoomView: STImageZoomView)
    
}

class STImageZoomView: UIView {
    
    weak var delegate: STImageZoomViewDelegate?
    
    let imageView = ImageView()
    private let zoomView = STZoomView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }
    
    //MARK: -  Private methods
    
    private func setupView() {
        self.zoomView.frame = self.bounds
        self.addSubview(self.zoomView)
        self.zoomView.delegate = self
        self.zoomView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.zoomView.contentView = self.imageView
        self.imageView.zoomView = self.zoomView
    }

}

extension STImageZoomView: STZoomViewDelegate {
    
    func zoomViewDidZoom(_ zoomView: STZoomView) {
        self.delegate?.zoomViewDidZoom(self)
    }

}

extension STImageZoomView {
    
    class ImageView: STImageView, IZoomContentView {
                
        private(set) var canZooming: Bool = false
        var zoomView: STZoomView?
                
        var aspectRatio: CGFloat {
            guard let image = self.image else { return 1 }
            return image.size.width / image.size.height
        }
        
        var contentSize: CGSize {
            guard let image = self.image else {
                return .zero
            }
            return image.size
        }
        
        override var image: UIImage? {
            didSet {
                self.zoomView?.zoomContent(didChange: self)
            }
        }
        
        override func setImage(_ images: STImageView.Images?, success: STImageView.ISuccess? = nil, progress: STImageView.IProgress? = nil, failure: STImageView.IFailure? = nil) {
            self.canZooming = false
            super.setImage(images, success: { [weak self] image in
                success?(image)
                self?.canZooming = true
            }, progress: progress, failure: failure)
        }
        
    }

}
