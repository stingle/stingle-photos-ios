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
    }
    
    
    lazy var supportTypes: [FileType: [UTType]] = {
        return self.calculateSupportTypes()
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()

        var user = STApplication.shared.utils.user()
        
        let mm = STApplication.shared.dataBase.galleryProvider.getAllObjects()
        

        self.manageImages()
    }
    
    
    //MARK: - Private methods
    
    private func manageImages() {
        
        let supportTypes = self.supportTypes
        let content = self.extensionContext!.inputItems[0] as! NSExtensionItem
        var inputItems = [NSItemProvider]()

        content.attachments?.forEach({ itemProvider in

            if let file =  self.calculateType(for: itemProvider) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: file.type.description) { url, error in
                    
                    print("ddddddd", itemProvider.suggestedName ?? "")
                    print("dddddddeee",  file.type.preferredFilenameExtension ?? "")

//                    PHAsset.init()
                    
//                    STImporter
                }


            }
        })

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
