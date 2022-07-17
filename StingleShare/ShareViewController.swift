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
        self.manageImages2()
    }
    
    //MARK: - Private methods
    
    private func manageImages2() {
        self.view.backgroundColor = .red
        let content = self.extensionContext!.inputItems[0] as! NSExtensionItem
        guard let attachments = content.attachments, !attachments.isEmpty else {
            self.endProcess()
            return
        }
        
        let importables = attachments.compactMap( {STImporter.GaleryItemProviderImportable.init(itemProvider: $0)} )
        _ = STImporter.GaleryFileImporter(importFiles: importables, responseQueue: .main, startHendler: {
            print("startHendler")
        }, progressHendler: { progress in
            print("progressHendler")
        }, complition: { files, importableFiles in
            print("complition")
        })
        
    }
    
    private func showLoginAlert() {
        self.endProcess()
    }
    
    private func endProcess() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
}
