//
//  STShareActivityVC.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/15/21.
//

import UIKit
import StingleRoot

protocol STFilesDownloaderActivityVCDelegate: AnyObject {
    func filesDownloaderActivity(didEndDownload activity: STFilesDownloaderActivityVC, decryptDownloadFiles: [STFilesDownloaderActivityVM.DecryptDownloadFile], folderUrl: URL?)
}

class STFilesDownloaderActivityVC: UIViewController {
  
    @IBOutlet weak private var preparingLabel: UILabel!
    @IBOutlet weak private var bgView: UIView!
    @IBOutlet weak private var progressView: STCircleProgressView!
    @IBOutlet weak private var cancelButton: UIButton!
    @IBOutlet weak private var progressBgView: STView!
    
    private weak var delegate: STFilesDownloaderActivityVCDelegate?
    private var downloadingFiles: DownloadFiles!
    private var viewModel: STFilesDownloaderActivityVM!
    private var isViewSetuped = false
    
    private(set) var userInfo: Any?
    
    class func showActivity(downloadingFiles: DownloadFiles, controller: UIViewController, delegate: STFilesDownloaderActivityVCDelegate, userInfo: Any? = nil) {
        let storyboard = UIStoryboard(name: "Share", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(identifier: "STShareActivityVCID") as! STFilesDownloaderActivityVC
        vc.downloadingFiles = downloadingFiles
        vc.delegate = delegate
        vc.userInfo = userInfo
        controller.present(vc, animated: false, completion: nil)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = STFilesDownloaderActivityVM(downloadingFiles: self.downloadingFiles)
        self.viewModel.delegate = self
        self.configureLocalized()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupView(completion: { end in
            if end {
                self.viewModel.srartDownload()
            }
        })
    }
 
    //MARK: - User acctions
    
    @IBAction private func didSelectCancelButton(_ sender: Any) {
        self.dismiss {
            self.viewModel.removeFolder()
        }
    }

    //MARK: - Private
    
    private func setupView(completion: @escaping ((Bool) -> Void)) {
        guard !self.isViewSetuped else {
            completion(false)
            return
        }
        self.isViewSetuped = true
        self.bgView.alpha = .zero
        self.progressBgView.alpha = .zero
        self.progressView.progress = .zero
        
        UIView.animate(withDuration: 0.3) {
            self.bgView.alpha = 0.35
            self.progressBgView.alpha = 1
        } completion: { _ in
            completion(true)
        }
    }
    
    private func configureLocalized() {
        self.preparingLabel.text = "preparing".localized
        self.cancelButton.setTitle("cancel".localized, for: .normal)
    }
    
    private func dismiss(completion: @escaping (() -> Void)) {
        self.viewModel.cancelAll()
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.bgView.alpha = .zero
            self?.progressBgView.alpha = .zero
        } completion: { _ in
            self.dismiss(animated: false, completion: nil)
            completion()
        }
    }
    
    private func dismiss(with decryptFiles: [STFilesDownloaderActivityVM.DecryptDownloadFile]) {
        self.dismiss {
            self.delegate?.filesDownloaderActivity(didEndDownload: self, decryptDownloadFiles: decryptFiles, folderUrl: self.viewModel.folderUrl)
        }
    }

}


extension STFilesDownloaderActivityVC {
    
    enum DownloadFiles {
        case files(files: [ILibraryFile])
        case albumFiles(album: STLibrary.Album, files: [STLibrary.AlbumFile])
    }
    
}

extension STFilesDownloaderActivityVC: STShareActivityVMDelegate {
    
    func shareActivityVM(didUpdedProgress vm: STFilesDownloaderActivityVM, progress: Double) {
        self.progressView.progress = CGFloat(progress)
    }
    
    func shareActivityVM(didFinished vm: STFilesDownloaderActivityVM, decryptFiles: [STFilesDownloaderActivityVM.DecryptDownloadFile]) {
        self.progressView.progress = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.dismiss(with: decryptFiles)
        }
    }
    
}
