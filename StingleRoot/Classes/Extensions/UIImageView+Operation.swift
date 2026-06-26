//
//  UIImageView+Operation.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/19/21.
//

import UIKit

public protocol IImageViewDownloadAnimator {
    func imageView(startAnimation imageView: UIImageView)
    func imageView(progressAnimation progress: (total: Float, completed: Float), imageView: UIImageView)
    func imageView(endAnimation imageView: UIImageView)
    func imageView(failEndAnimation imageView: UIImageView)
}

public extension UIImageView {
    
    private static var retryerIdentifier: UInt8 = 0
    
    typealias ISuccess = (_ result: UIImage?) -> Void
    typealias IProgress = (_ progress: Progress) -> Void
    typealias IFailure = (_ error: IError) -> Void
    
    static let imageRetryer = STApplication.shared.downloaderManager.imageRetryer
    
    private(set) var retryerIdentifier: String? {
        get {
            return (objc_getAssociatedObject(self, &Self.retryerIdentifier) as? String)
        } set {
            objc_setAssociatedObject(self, &Self.retryerIdentifier, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
        
    func setImage(source: IDownloaderSource?, placeholder: UIImage? = nil, animator: IImageViewDownloadAnimator? = nil, success: ISuccess? = nil, progress: IProgress? = nil, failure: IFailure? = nil, saveOldImage: Bool = false) {
        
        if let retryerIdentifier = self.retryerIdentifier, !saveOldImage {
            Self.imageRetryer.cancel(operation: retryerIdentifier)
            self.retryerIdentifier = nil
        }

        // Fast path: if the decoded image is already in the in-memory cache, show it synchronously.
        // The normal path clears the image to nil, starts the grey placeholder animation, and resolves
        // even a cache hit via the operation queue + DispatchQueue.main.async — so every reconfigured
        // cell flashes grey for a runloop. That's invisible for a single cell but, when a whole sync
        // reload reconfigures every visible cell at once, the entire gallery flashes grey. A synchronous
        // memory hit avoids the nil-gap entirely.
        //
        // Only for fire-and-forget display callers (`success == nil`, i.e. grid cells). Callers that
        // pass a `success` closure drive a load lifecycle (e.g. the photo viewer chains thumb→full and
        // sets the image in `viewDidLoad`); for them the original async timing matters — setting the
        // image synchronously before the zoom view has real bounds sizes it to zero (a black frame).
        if success == nil, let source = source, let cachedImage = Self.imageRetryer.memoryCachedImage(source: source) {
            // We have the final image, so cancel any still-in-flight op (the `saveOldImage` path skips
            // the cancel above) — otherwise its later callback could overwrite this image.
            if let retryerIdentifier = self.retryerIdentifier {
                Self.imageRetryer.cancel(operation: retryerIdentifier)
            }
            self.retryerIdentifier = nil
            self.image = cachedImage
            animator?.imageView(endAnimation: self)
            success?(cachedImage)
            return
        }

        if !saveOldImage {
            self.image = nil
        }

        if let source = source {
            animator?.imageView(startAnimation: self)
            self.retryerIdentifier = Self.imageRetryer.download(source: source) { [weak self] (image) in
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
