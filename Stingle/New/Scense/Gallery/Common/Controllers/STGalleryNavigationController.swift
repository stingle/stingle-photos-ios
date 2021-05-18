//
//  STGalleryNavigationController.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/15/21.
//

import UIKit

class STGalleryNavigationController: STNavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        STApplication.shared.downloaderManager.fileDownloader.add(self)
    }

}

extension STGalleryNavigationController: STFileDownloaderObserver {
    
    func downloader(didUpdedProgress downloader: STDownloaderManager.FileDownloader) {
        DispatchQueue.main.async { [weak self] in
            let hasProgress = downloader.hasProgress()
            self?.navigationBar.setProgressView(isHidden: !hasProgress)
            let progress: Float = Float(downloader.progress())
            self?.navigationBar.setProgress(progress: progress)
        }
    }
    
    func downloader(didFinished downloader: STDownloaderManager.FileDownloader) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationBar.setProgressView(isHidden: true)
        }
    }
    
}


