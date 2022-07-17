//
//  ShareViewController.swift
//  FileSharing
//
//  Created by Khoren Asatryan on 28.06.22.
//

import Intents
import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import StingleRoot
import Photos

class ShareViewController: UIViewController {
    
    enum FileType {
        case image
        case video
        
        var headerFileType: StingleRoot.STHeader.FileType {
            switch self {
            case .image:
                return .image
            case .video:
                return .video
            }
        }
    }
     
    override func viewDidLoad() {
        super.viewDidLoad()
        guard STApplication.shared.utils.user() != nil else {
            self.showLoginAlert()
            return
        }
        self.manageImages()
    }
    
    //MARK: - Private methods
    
    private func manageImages() {
        let content = self.extensionContext!.inputItems[0] as! NSExtensionItem
        guard let attachments = content.attachments, !attachments.isEmpty else {
            self.cancelRequest(error: ShareViewControllerError.emptyData)
            return
        }
        let progressView = STProgressView()
        progressView.title = "importing".localized
        progressView.subTitle = "\(0)/\(attachments.count)"
        progressView.show(in: self.view)
        let importables = attachments.compactMap( {STImporter.GaleryItemProviderImportable(itemProvider: $0)} )
        _ = STImporter.GaleryFileImporter(importFiles: importables, responseQueue: .main, startHendler: {}, progressHendler: { progress in
            let progressValue = progress.totalUnitCount == .zero ? .zero : Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    progressView.progress = Float(progressValue)
                    let number = progress.completedUnitCount + 1
                    progressView.subTitle = "\(number)/\(progress.totalUnitCount)"
                }
            }
        }, complition: { files, importableFiles in
            let files = importableFiles.map({$0.itemProvider})
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.3, execute: { [weak self] in
                progressView.hide()
                self?.endProcess(providers: files)                
            })
        }, uploadIfNeeded: true)
    }
    
    private func showLoginAlert() {
        self.cancelRequest(error:  ShareViewControllerError.loginError)
    }
    
    private func cancelRequest(error: ShareViewControllerError) {
        self.showError(error: error, handler: { [weak self] in
            self?.endProcess(providers: [])
        })
    }
        
    private func endProcess(providers: [NSItemProvider]) {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
}

extension ShareViewController {
    
    enum ShareViewControllerError: Error, CustomStringConvertible, IError {
        case loginError
        case emptyData
        
        var description: String {
            switch self {
            case .loginError:
                return "please_login_in_app".localized
            case .emptyData:
                return "you_havent_selected_any_item".localized
            }
        }
        
        var message: String {
            return self.description
        }
    }
    
    fileprivate func showError(error: IError, handler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
        let okAction = UIAlertAction(title:  "ok".localized, style: .default) { (_) in
            handler?()
        }
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
    
}
