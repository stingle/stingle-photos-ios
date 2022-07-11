//
//  STGallerySyncBurButton.swift
//  Stingle
//
//  Created by Khoren Asatryan on 4/21/21.
//

import UIKit
import StingleRoot

@IBDesignable class STGallerySyncView: UIControl {
    
    private let circleProgressView = STCircleProgressView()
    private let syncManager = STApplication.shared.syncManager
    private let uploader = STApplication.shared.uploader

    @IBInspectable var progressColor: UIColor {
        set {
            self.circleProgressView.progressColor = newValue
        } get {
            return self.circleProgressView.progressColor
        }
    }
    
    @IBInspectable var trackColor: UIColor {
        set {
            self.circleProgressView.trackColor = newValue
        } get {
            return self.circleProgressView.trackColor
        }
    }
    
    @IBInspectable var borderInset: CGFloat {
        set {
            self.circleProgressView.borderInset = newValue
        } get {
            return self.circleProgressView.borderInset
        }
    }
    
    @IBInspectable private(set) var progress: CGFloat {
        set {
            self.circleProgressView.progress = newValue
        } get {
            return self.circleProgressView.progress
        }
    }
    
    override var isHighlighted: Bool {
        set {
            self.alpha = newValue ? 0.5 : 1
            super.isHighlighted = newValue
        } get {
            return super.isHighlighted
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    //MARK: - Public
    
    func startAnimating() {
        self.circleProgressView.startAnimating()
    }
    
    func stopAnimating() {
        self.circleProgressView.stopAnimating()
    }
    
    //MARK: - Private
    
    private func setup() {
        self.circleProgressView.isUserInteractionEnabled = false
        self.addSubviewFullContent(view: self.circleProgressView)
        self.circleProgressView.progress = 0.6
        self.circleProgressView.lineWidth = 2
        self.circleProgressView.progressLineWidth = 4
        self.progress = .zero
        self.updateImage()
        self.uploader.addListener(self)
        self.syncManager.addListener(self)
    }
    
    private func updateImage() {
        if self.syncManager.isSyncing {
            self.circleProgressView.startAnimating()
        } else {
            self.uploader.isProgress { [weak self] isProgress in
                DispatchQueue.main.async {
                    if isProgress {
                        let image = UIImage(named: "ic_sync_nav_uploading")
                        self?.circleProgressView.image = image
                        self?.circleProgressView.stopAnimating()
                    } else {
                        let image = UIImage(named: "ic_sync_nav_completed")
                        self?.circleProgressView.image = image
                        self?.circleProgressView.stopAnimating()
                    }
                }
            }
        }
    }
    
}

extension STGallerySyncView: IFileUploaderObserver {
    
    func fileUploader(didChanged uploader: STFileUploader, uploadInfo: STFileUploader.UploadInfo) {
        DispatchQueue.main.async { [weak self] in
            let progress = uploadInfo.fractionCompleted
            if uploadInfo.progresses.isEmpty {
                self?.progress = 0
            } else {
                self?.progress = CGFloat(progress)
            }
            self?.updateImage()
        }
    }
    
}

extension STGallerySyncView: ISyncManagerObserver {
    
    func syncManager(didStartSync syncManager: STSyncManager) {
        self.updateImage()
    }
    
    func syncManager(didEndSync syncManager: STSyncManager, with error: IError?) {
        self.updateImage()
    }
    
}
