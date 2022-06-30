//
//  ShareViewController.swift
//  FileSharing
//
//  Created by Khoren Asatryan on 28.06.22.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers


class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.manageImages()
    }
    
    
    func manageImages() {
        
        var supportTypes = Set<String>()
        supportTypes.insert(String(describing: UTType.image))
        supportTypes.insert(String(describing: UTType.gif))
        supportTypes.insert(String(describing: UTType.video))
                        
        let content = self.extensionContext!.inputItems[0] as! NSExtensionItem
        
        var inputItems = [NSItemProvider]()
        content.attachments?.forEach({ itemProvider in
            let registeredTypeIdentifiers = Set(itemProvider.registeredTypeIdentifiers)
            if registeredTypeIdentifiers.isStrictSubset(of: supportTypes) {
                inputItems.append(itemProvider)
            }
            
            
            
            let mm = itemProvider.registeredTypeIdentifiers
            
            
            let kk = itemProvider.hasItemConformingToTypeIdentifier(imageType)
            let kkr = itemProvider.hasItemConformingToTypeIdentifier(videoType)
            
            
            print("")
            
        })
        
        
        print("")
        
        
//        let contentType = kUTTypeImage as String
//
//        for (index, attachment) in (content.attachments as! [NSItemProvider]).enumerated() {
//            if attachment.hasItemConformingToTypeIdentifier(contentType) {
//
//                attachment.loadItem(forTypeIdentifier: contentType, options: nil) { [weak self] data, error in
//
//                    if error == nil, let url = data as? URL, let this = self {
//                        do {
//
//                            // GETTING RAW DATA
//                            let rawData = try Data(contentsOf: url)
//                            let rawImage = UIImage(data: rawData)
//
//                            // CONVERTED INTO FORMATTED FILE : OVER COME MEMORY WARNING
//                            // YOU USE SCALE PROPERTY ALSO TO REDUCE IMAGE SIZE
//                            let image = UIImage.resizeImage(image: rawImage!, width: 100, height: 100)
//                            let imgData = UIImagePNGRepresentation(image)
//
//                            this.selectedImages.append(image)
//                            this.imagesData.append(imgData!)
//
//                            if index == (content.attachments?.count)! - 1 {
//                                DispatchQueue.main.async {
//                                    this.imgCollectionView.reloadData()
//                                    let userDefaults = UserDefaults(suiteName: "group.com.nickelfox.testpush")
//                                    userDefaults?.set(this.imagesData, forKey: this.sharedKey)
//                                    userDefaults?.synchronize()
//                                }
//                            }
//                        }
//                        catch let exp {
//                            print("GETTING EXCEPTION \(exp.localizedDescription)")
//                        }
//
//                    } else {
//                        print("GETTING ERROR")
//                        let alert = UIAlertController(title: "Error", message: "Error loading image", preferredStyle: .alert)
//
//                        let action = UIAlertAction(title: "Error", style: .cancel) { _ in
//                            self?.dismiss(animated: true, completion: nil)
//                        }
//
//                        alert.addAction(action)
//                        self?.present(alert, animated: true, completion: nil)
//                    }
//                }
//            }
//        }
    }
    
}
