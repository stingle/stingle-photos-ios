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
    private static var sourceIdentifier: String = "sourceIdentifier"
    
    typealias ISuccess = (_ result: UIImage) -> Void
    typealias IProgress = (_ progress: Progress) -> Void
    typealias IFailure = (_ error: IError) -> Void
    
    private(set) var retryerIdentifier: String? {
        get {
            return (objc_getAssociatedObject(self, &Self.retryerIdentifier) as? String)
        } set {
            objc_setAssociatedObject(self, &Self.retryerIdentifier, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    private(set) var source: IRetrySource? {
        get {
            return (objc_getAssociatedObject(self, &Self.sourceIdentifier) as? IRetrySource)
        } set {
            objc_setAssociatedObject(self, &Self.sourceIdentifier, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
        
    func setImage(source: IRetrySource?, placeholder: UIImage? = nil, animator: IImageViewDownloadAnimator? = nil, success: ISuccess? = nil, progress: IProgress? = nil, failure: IFailure? = nil) {
        
        if let retryerIdentifier = self.retryerIdentifier {
            STApplication.shared.fileRetryer.imageRetryer.cancel(operation: retryerIdentifier)
        }
                
        if let source = source {
            self.source = source
            self.image = placeholder
            animator?.imageView(startAnimation: self)
            self.retryerIdentifier = STApplication.shared.fileRetryer.imageRetryer.retry(source: source) { [weak self] (image) in
                self?.source = nil
                self?.retrySuccess(image: image, animator: animator, success: success)
            } progress: { [weak self] (progress) in
                self?.retryProgress(progressRetry: progress, animator: animator)
            } failure: { [weak self] (error) in
                self?.retryFailure(error: error, animator: animator)
                self?.source = nil
            }
        } else {
            self.image = placeholder
            animator?.imageView(endAnimation: self)
        }
    }
    
    //MARK: - Private
    
    private func retrySuccess(image: UIImage, animator: IImageViewDownloadAnimator?, success: ISuccess? = nil) {
        DispatchQueue.main.async {
            animator?.imageView(endAnimation: self)
            self.image = image
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
            gradientView.addFadeAnimation()
            gradientView.isHidden = false
        } else {
            let gradientView = STGradientView(frame: view.bounds)
            let color = UIColor.appPrimary.withAlphaComponent(0.3)
            gradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            gradientView.backgroundColor = color
            gradientView.colors.removeAll()
            gradientView.tag = Self.animationViewTag
            gradientView.addFadeAnimation()
            view.addSubview(gradientView)
        }
    }
    
    private func removeAnimation(view: UIView) {
        let loadingView = view.viewWithTag(Self.animationViewTag) as? STGradientView
        loadingView?.isHidden = true
        loadingView?.removeAllAnimation()
    }
    
}
