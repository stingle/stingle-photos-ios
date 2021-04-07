//
//  STHomeSyncCollectionReusableView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 3/29/21.
//

import UIKit

class STHomeSyncCollectionReusableView: UICollectionReusableView {

    enum State {
        case syncComplete
        case refreshing
        case uploading(image: IRetrySource, count: Int, currentIndex: Int, progress: CGFloat)
    }
    
    @IBOutlet weak private var backgroundView: UIView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var iconImageView: UIImageView!
    @IBOutlet weak private var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak private var imageView: STImageView!
    @IBOutlet weak private var progressView: UIProgressView!
    
    private var state = State.syncComplete
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.configure(state: .syncComplete)
    }

    func update(alpha: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.backgroundView.alpha = alpha
        }
    }
    
    func configure(state: State) {
        self.state = state
        switch self.state {
        case .syncComplete:
            self.setSyncComplete()
        case .refreshing:
            self.setRefreshing()
        case .uploading(let image, let count, let currentIndex, let progress):
            self.setUploading(image: image, count: count, currentIndex: currentIndex, progress: progress)
        }
        
    }
    
    //MARK: - Private
    
    func setSyncComplete() {
        self.progressView.isHidden = true
        self.iconImageView.isHidden = false
        self.activityIndicatorView.stopAnimating()
        self.imageView.isHidden = true
        self.titleLabel.text = "sync_backup_complete".localized
    }
    
    func setRefreshing() {
        self.progressView.isHidden = true
        self.iconImageView.isHidden = true
        self.activityIndicatorView.startAnimating()
        self.imageView.isHidden = true
        self.titleLabel.text = "sync_refreshing".localized
    }
    
    func setUploading(image: IRetrySource, count: Int, currentIndex: Int, progress: CGFloat) {
        self.progressView.isHidden = false
        self.iconImageView.isHidden = true
        self.activityIndicatorView.stopAnimating()
        self.imageView.isHidden = false
        let title = String(format: "sync_uploading_file_of_out", "\(currentIndex)", "\(count)")
        self.titleLabel.text = title
        self.progressView.progress = Float(progress)
        self.imageView.setImage(source: image, placeholder: nil)
    }
    
}
