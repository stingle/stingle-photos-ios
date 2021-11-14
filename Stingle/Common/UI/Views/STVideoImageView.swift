//
//  STVideoImageViewView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 11/12/21.
//

import UIKit

class STVideoImageView: UIView {
    
    private(set) var videoView: STVideoView!
    private(set) var imageView: STImageView!
    
    private(set) var imageSource: IDownloaderSource?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override var contentMode: UIView.ContentMode {
        didSet {
            
            if let imageView = self.imageView {
                imageView.contentMode = self.contentMode
            }
            
            if let videoView = self.videoView {
                videoView.contentMode = self.contentMode
            }
        }
    }
    
    //MARK: - Private methods
    
    private func setup() {
        self.setupImageView()
        self.setupVideoView()
    }
    
    private func setupImageView() {
        self.imageView = STImageView(frame: self.bounds)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(self.imageView)
    }
    
    private func setupVideoView() {
        self.videoView = STVideoView(frame: self.bounds)
        self.videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(self.videoView)
        self.videoView.backgroundColor = .clear
    }
    
}

extension STVideoImageView {
    
    func setImage(source: IDownloaderSource?, placeholder: UIImage? = nil, animator: IImageViewDownloadAnimator? = nil, success: UIImageView.ISuccess? = nil, progress: UIImageView.IProgress? = nil, failure: UIImageView.IFailure? = nil, saveOldImage: Bool = false) {
        self.imageSource = source
        self.imageView.setImage(source: source, placeholder: placeholder, animator: animator, success: success, progress: progress, failure: failure, saveOldImage: saveOldImage)
    }
    
    func setPlayer(player: STPlayer?) {
        self.videoView.setPlayer(player: player)
    }
    
}

extension STVideoImageView: INavigationAnimatorSourceView {
    
    func previewContentSizeNavigationAnimator() -> CGSize? {
        if self.videoView.isReadyForDisplay {
            return self.videoView.videoRect.size
        } else {
            return self.imageView.previewContentSizeNavigationAnimator()
        }
    }
    
    func createPreviewNavigationAnimator() -> UIView {
        var frame = self.bounds
        if let size = self.previewContentSizeNavigationAnimator() {
            frame = self.culculateDrawRect(contentSize: size)
        }
        let result = STVideoImageView(frame: frame)
        result.imageView.setImage(source: self.imageSource)
        result.setPlayer(player: self.videoView.stPlayer)
        return result
    }
    
    func previewContentModeNavigationAnimator() -> STNavigationAnimator.ContentMode {
        return .fit
    }
    
}
