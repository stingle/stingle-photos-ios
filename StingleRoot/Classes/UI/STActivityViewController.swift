//
//  STActivityViewController.swift
//  StingleRoot
//
//  Created by Khoren Asatryan on 18.07.22.
//

import UIKit


public class STActivityViewController: UIActivityViewController {
    
    public typealias Complition = () -> Void
    public var complition: Complition?
    
    deinit {
        self.complition?()
        self.complition = nil
    }
    
}

//TODO: - Khoren implement

//extension STActivityViewController {
//
//    class ItemsConfiguration: NSObject  {
//
//        let files: [STLibrary.FileBase]
//        var itemProvidersForActivityItemsConfiguration: [NSItemProvider]
//
//        init(files: [STLibrary.FileBase]) {
//            self.files = files
//
////            NSItemProvider.init(item: NSSecureCoding?, typeIdentifier: <#T##String?#>)
//        }
//
//    }
//
//}
//
//extension STActivityViewController.ItemsConfiguration: UIActivityItemsConfigurationReading {
//
//
//
//}
//
//
//extension STActivityViewController.ItemsConfiguration {
//
//    class ItemProvider: NSItemProvider {
//
//        let file: ILibraryFile
//        let fileHeader: STHeader
//        let thumbHeader: STHeader
//
//        override var registeredTypeIdentifiers: [String] {
//            if let uiType = fileHeader.uiType {
//                return [uiType.description]
//            }
//            return []
//        }
//
//        init?(file: ILibraryFile) {
//            guard let fileHeader = file.decryptsHeaders.file, let thumbHeader = file.decryptsHeaders.thumb else {
//                return nil
//            }
//            self.fileHeader = fileHeader
//            self.thumbHeader = thumbHeader
//            self.file = file
//            super.init()
//        }
//
//        override func hasItemConformingToTypeIdentifier(_ typeIdentifier: String) -> Bool {
//            return self.registeredTypeIdentifiers.contains(where: { $0 == typeIdentifier })
//        }
//
//        override func hasRepresentationConforming(toTypeIdentifier typeIdentifier: String, fileOptions: NSItemProviderFileOptions = []) -> Bool {
//            return self.registeredTypeIdentifiers.contains(where: { $0 == typeIdentifier })
//        }
//
//        override func loadDataRepresentation(forTypeIdentifier typeIdentifier: String, completionHandler: @escaping (Data?, Error?) -> Void) -> Progress {
//
//            let ff =  STDownloaderManager.FileDownloader()
//
//            let gg = STDownloaderManager.FileDownloaderSource(file: self.file, fileSaveUrl: URL(fileURLWithPath: ""), isThumb: false)
//
//
//            ff.download(source: gg) { result in
//
//            } progress: { progress in
//
//            } failure: { error in
//
//            }
//
//
//        }
//
//        override func loadFileRepresentation(forTypeIdentifier typeIdentifier: String, completionHandler: @escaping (URL?, Error?) -> Void) -> Progress {
//
//
//        }
//
//        override func loadInPlaceFileRepresentation(forTypeIdentifier typeIdentifier: String, completionHandler: @escaping (URL?, Bool, Error?) -> Void) -> Progress {
//
//
//        }
//
//
//        override func canLoadObject(ofClass aClass: NSItemProviderReading.Type) -> Bool {
//
//        }
//
//
//        override func loadItem(forTypeIdentifier typeIdentifier: String, options: [AnyHashable : Any]? = nil, completionHandler: NSItemProvider.CompletionHandler? = nil) {
//
//        }
//
//        override func registerDataRepresentation(forTypeIdentifier typeIdentifier: String, visibility: NSItemProviderRepresentationVisibility, loadHandler: @escaping (@escaping (Data?, Error?) -> Void) -> Progress?) {
//
//
//        }
//
//        override func registerFileRepresentation(forTypeIdentifier typeIdentifier: String, fileOptions: NSItemProviderFileOptions = [], visibility: NSItemProviderRepresentationVisibility, loadHandler: @escaping (@escaping (URL?, Bool, Error?) -> Void) -> Progress?) {
//
//        }
//
//    }
//
//}
