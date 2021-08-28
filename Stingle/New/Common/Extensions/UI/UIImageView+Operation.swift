//
//  UIImageView+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/19/21.
//

import UIKit

protocol IImageViewDownloadAnimator {
    func imageView(startAnimation imageView: UIImageView)
    func imageView(progressAnimation progress: (total: Float, completed: Float), imageView: UIImageView)
    func imageView(endAnimation imageView: UIImageView)
    func imageView(failEndAnimation imageView: UIImageView)
}

extension UIImageView {
    
    private static var retryerIdentifier: String = "retryerIdentifier"
    
    typealias ISuccess = (_ result: UIImage?) -> Void
    typealias IProgress = (_ progress: Progress) -> Void
    typealias IFailure = (_ error: IError) -> Void
    
    private(set) var retryerIdentifier: String? {
        get {
            return (objc_getAssociatedObject(self, &Self.retryerIdentifier) as? String)
        } set {
            objc_setAssociatedObject(self, &Self.retryerIdentifier, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
        
    func setImage(source: IDownloaderSource?, placeholder: UIImage? = nil, animator: IImageViewDownloadAnimator? = nil, success: ISuccess? = nil, progress: IProgress? = nil, failure: IFailure? = nil, saveOldImage: Bool = false) {
        
        if let retryerIdentifier = self.retryerIdentifier {
            STApplication.shared.downloaderManager.imageRetryer.cancel(operation: retryerIdentifier)
            self.retryerIdentifier = nil
        }
        
        if !saveOldImage {
            self.image = nil
        }
        
        if let source = source {
            animator?.imageView(startAnimation: self)
            self.retryerIdentifier = STApplication.shared.downloaderManager.imageRetryer.download(source: source) { [weak self] (image) in
                self?.retryerIdentifier = nil
                self?.retrySuccess(image: image, animator: animator, success: success)
            } progress: { [weak self] (progress) in
                self?.retryProgress(progressRetry: progress, animator: animator)
            } failure: { [weak self] (error) in
                self?.retryerIdentifier = nil
                self?.retryFailure(error: error, animator: animator, failure: failure)
            }
        } else {
            self.image = placeholder
            animator?.imageView(endAnimation: self)
            self.retryerIdentifier = nil
            success?(nil)
        }
    }
    
    //MARK: - Private
    
    private func retrySuccess(image: UIImage, animator: IImageViewDownloadAnimator?, success: ISuccess? = nil) {
        DispatchQueue.main.async {
            animator?.imageView(endAnimation: self)
            self.image = image
            success?(image)
        }
    }
    
    private func retryProgress(progressRetry: Progress, animator: IImageViewDownloadAnimator?, progress: IProgress? = nil) {
        DispatchQueue.main.async {
            let totalUnitCount = Float(progressRetry.totalUnitCount)
            let completedUnitCount = Float(progressRetry.completedUnitCount)
            animator?.imageView(progressAnimation: (totalUnitCount,completedUnitCount), imageView: self)
            progress?(progressRetry)
        }
    }
    
    private func retryFailure(error: IError, animator: IImageViewDownloadAnimator?, failure: IFailure? = nil) {
        guard !error.isCancelled else {
            return
        }
        DispatchQueue.main.async {
            animator?.imageView(failEndAnimation: self)
            failure?(error)
        }
    }
    
        
}

class STImageDownloadPlainAnimator: IImageViewDownloadAnimator {
    
    static private let animationViewTag = 10003
    
    func imageView(startAnimation imageView: UIImageView) {
        self.addAnimation(view: imageView)
    }
    
    func imageView(progressAnimation progress: (total: Float, completed: Float), imageView: UIImageView) {}
    
    func imageView(endAnimation imageView: UIImageView) {
        self.removeAnimation(view: imageView)
    }
    
    func imageView(failEndAnimation imageView: UIImageView) {
        self.removeAnimation(view: imageView)
    }
    
    //MARK: - Private func
    
    private func addAnimation(view: UIView) {
        if let gradientView = view.viewWithTag(Self.animationViewTag) as? STGradientView {
            gradientView.addFadeAnimation(fromValue: 1, toValue: 0.5, byValue: 0.5)
            gradientView.isHidden = false
        } else {
            let gradientView = STGradientView(frame: view.bounds)
            let color = UIColor.appPlaceholder
            gradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            gradientView.backgroundColor = .clear
            gradientView.colors = [color]
            gradientView.tag = Self.animationViewTag
            gradientView.addFadeAnimation(fromValue: 1, toValue: 0.5, byValue: 0.5)
            view.addSubview(gradientView)
        }
    }
    
    private func removeAnimation(view: UIView) {
        let loadingView = view.viewWithTag(Self.animationViewTag) as? STGradientView
        loadingView?.isHidden = true
        loadingView?.removeAllAnimation()
    }
    
}
