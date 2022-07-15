//
//  IImportable+URL.swift
//  StingleRoot
//
//  Created by Khoren Asatryan on 13.07.22.
//

import Foundation
import UniformTypeIdentifiers
import UIKit
import AVFoundation

public protocol IItemProviderImportable: IImportableFile {

    var itemProvider: NSItemProvider { get }
    
}

public extension IItemProviderImportable {
    
    
    func requestData(in queue: DispatchQueue?, progress: STImporter.ProgressHandler?, success: @escaping (STImporter.ImportFileInfo) -> Void, failure: @escaping (IError) -> Void) {
        
//        var headerFileType: STHeader
//
//
//        for registeredTypeIdentifiers in self.itemProvider.registeredTypeIdentifiers {
//
//
//
//        }
        
       var mm = self.itemProvider.registeredTypeIdentifiers
        
        
        itemProvider.loadObject(ofClass: AVURLAsset.self) { asset, error in
            print("")
        }
//
        itemProvider.loadObject(ofClass: UIImage.self) { image, error in
            print("")
        }
        
//        itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.description) { url, error in
//
//            print("")
//
//        }
        
    }
    
    
    
    
    private func calculateType(for itemProvider: NSItemProvider) -> (fileType: STHeader.FileType, type: UTType)? {
        let supportTypes = self.calculateSupportTypes()
        for (fileType, tTypes) in supportTypes {
            for tType in tTypes {
                guard itemProvider.registeredTypeIdentifiers.contains(tType.description) else {
                    continue
                }
                return (fileType, tType)
            }
        }
        return nil
    }
    
    private func calculateSupportTypes() -> [STHeader.FileType: [UTType]] {
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

extension STImporter {
            
    public class GaleryItemProviderImportable: IItemProviderImportable, GaleryImportable {
        
        public var itemProvider: NSItemProvider
        
        public init(itemProvider: NSItemProvider) {
            self.itemProvider = itemProvider
        }
        
    }
    
    
    
}

//NSItemProvider
