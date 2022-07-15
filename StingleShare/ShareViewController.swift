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
    
    lazy var supportTypes: [FileType: [UTType]] = {
        return self.calculateSupportTypes()
    }()
        
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
    
//    private func manageImages() {
//        let content = self.extensionContext!.inputItems[0] as! NSExtensionItem
////        var fileURLs = [STImporter.FileURL]()
//        var count = content.attachments?.count ?? .zero
//        content.attachments?.forEach({ itemProvider in
//            if let file =  self.calculateType(for: itemProvider) {
//
//
//                itemProvider.loadFileRepresentation(forTypeIdentifier: file.type.description) { [weak self] url, error in
//                    if let url = url, error == nil, url.isFileURL {
//
//
//                        let environment = STEnvironment.current
//                        let id = "group." + environment.appFileSharingBundleId
//                        var storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
//                        storeURL = storeURL?.appendingPathComponent(environment.productName)
//
//
//
////                        let fileURL = STImporter.FileURL(fileUrl: url, fileType: file.fileType.headerFileType)
//
//
//
//
//                        let image = UIImage.init(contentsOfFile: url.path)
//                        print("")
//
//                    }
//                    count = count - 1
//                    if count == .zero {
//                        DispatchQueue.main.async {
//                            self?.importFileURLs(fileURLs: fileURLs)
//                        }
//                    }
//                }
//            } else {
//                count = count - 1
//                if count == .zero {
//                    self.importFileURLs(fileURLs: fileURLs)
//                }
//            }
//        })
//    }
    
//    private func importFileURLs(fileURLs: [STImporter.FileURL]) {
//        guard !fileURLs.isEmpty else {
//            self.endProcess()
//            return
//        }
//
//        let importables = fileURLs.compactMap({ STImporter.GaleryFileURLImportable(fileURL: $0) })
//
//        _ = STImporter.GaleryFileImporter(importFiles: importables, responseQueue: .main) {
//
//            print("start")
//
//        } progressHendler: { progress in
//
//            print("progress")
//
//        } complition: { files, importableFiles in
//
//            print("complition")
//
//        }
//
//
//        print("")
//
//    }
    
    private func showLoginAlert() {
        self.endProcess()
    }
    
    private func endProcess() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func calculateType(for itemProvider: NSItemProvider) -> (fileType: FileType, type: UTType)? {
        for (fileType, tTypes) in self.supportTypes {
            for tType in tTypes {
                guard itemProvider.registeredTypeIdentifiers.contains(tType.description) else {
                    continue
                }
                return (fileType, tType)
            }
        }
        return nil
    }
    
    private func calculateSupportTypes() -> [FileType: [UTType]] {
        let imagesTypes = [UTType.heic,
                            UTType.rawImage,
                            UTType.tiff,
                            UTType.tiff,
                            UTType.gif,
                            UTType.heif,
                            UTType.svg,
                            UTType.ico,
                            UTType.jpeg,
                            UTType.image,
                            UTType.png,
                            UTType.icns,
                            UTType.bmp,
                            UTType.livePhoto,
                            UTType.webP]
        
        let videoTypes = [UTType.avi,
                            UTType.appleProtectedMPEG4Video,
                            UTType.quickTimeMovie,
                            UTType.movie,
                            UTType.mpeg4Movie,
                            UTType.mpeg2Video,
                            UTType.mpeg,
                            UTType.video]

        
        return [.image: imagesTypes, .video: videoTypes]
    }
    
    
}


extension ShareViewController: NSFilePresenter {
    
    var sharedUrl: URL {
        let id = STEnvironment.current.appFileSharingBundleId
        let sharedUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
        return sharedUrl!
    }
        
    var presentedItemURL: URL? {
        return self.sharedUrl.appendingPathComponent("Items")
    }
    
    var presentedItemOperationQueue: OperationQueue {
        return .main
    }
    
    func presentedItemDidChange() {
        
    }
    
}
