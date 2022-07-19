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
        
        func compled(error: IError) {
            if let queue = queue {
                queue.async {
                    failure(error)
                }
            } else {
                failure(error)
            }
        }
        
        func compled(importFileInfo: STImporter.ImportFileInfo) {
            if let queue = queue {
                queue.async {
                    success(importFileInfo)
                }
            } else {
                success(importFileInfo)
            }
        }
        
        func compled(_ progressing: Progress, _ stop: inout Bool?) {
            progress?(progressing, &stop)
        }
        
        guard let type = self.calculateType(for: self.itemProvider) else {
            compled(error: STImporter.ImporterError.fileNotSupport)
            return
        }
        
        self.requestData(type: type, progress: { progress, stop in
            compled(progress, &stop)
        }, success: { importFileInfo in
            compled(importFileInfo: importFileInfo)
        }, failure: { error in
            compled(error: error)
        })
    }
    
    private func requestData(type: UTType, progress: STImporter.ProgressHandler?, success: @escaping (STImporter.ImportFileInfo) -> Void, failure: @escaping (IError) -> Void) {
        switch type.headerFileType {
        case .image:
            self.requestImage(type: type, progress: progress, success: success, failure: failure)
        case .video:
            self.requestVideo(type: type, progress: progress, success: success, failure: failure)
        default:
            failure(STImporter.ImporterError.fileNotSupport)
        }
        
    }
    
    private func requestImage(type: UTType, progress: STImporter.ProgressHandler?, success: @escaping (STImporter.ImportFileInfo) -> Void, failure: @escaping (IError) -> Void) {
        
        func imageDidLoaded(image: UIImage, url: URL?) {
                        
            guard let imageData = image.imageData(for: type) ?? image.jpegData(compressionQuality: 1), let thumbnailData = image.thumbnailData, let headerFileType = type.headerFileType else {
                failure(STImporter.ImporterError.fileNotSupport)
                return
            }
            
            let id = UUID().uuidString
            let fileManager = FileManager.default
            var temporaryDirectory = fileManager.temporaryDirectory
            temporaryDirectory = temporaryDirectory.appendingPathComponent(id)
            let fileFolderURL = temporaryDirectory

            do {
                
                if let lastPathComponent = url?.lastPathComponent {
                    temporaryDirectory = temporaryDirectory.appendingPathComponent(lastPathComponent)
                } else if let suggestedName = self.itemProvider.suggestedName {
                    temporaryDirectory = temporaryDirectory.appendingPathComponent(suggestedName)
                }
                
                if temporaryDirectory.pathExtension.isEmpty {
                    let preferredFilenameExtension = type.preferredFilenameExtension ?? "JPEG"
                    temporaryDirectory = temporaryDirectory.appendingPathExtension(preferredFilenameExtension)
                }
                
                try? fileManager.createDirectory(at: fileFolderURL, withIntermediateDirectories: true)
                try imageData.write(to: temporaryDirectory)
            } catch {
                try? fileManager.removeItem(at: fileFolderURL)
                failure(STImporter.ImporterError.fileNotSupport)
                return
            }
           
            let date = Date()
            let info = STImporter.ImportFileInfo(oreginalUrl: temporaryDirectory, thumbImage: thumbnailData, fileType: headerFileType, duration: .zero, fileSize: UInt(imageData.count), creationDate: date, modificationDate: date) {
                try? fileManager.removeItem(at: fileFolderURL)
            }
            success(info)
        }
        
        func loadInPlaceFile() {
            self.itemProvider.loadInPlaceFileRepresentation(forTypeIdentifier: type.description) { url, inPlaceFile, error in
                guard let url = url, let image = UIImage(contentsOfFile: url.path) else {
                    failure(STImporter.ImporterError.fileNotSupport)
                    return
                }
                imageDidLoaded(image: image, url: url)
            }
        }
        
        func loadObjectImage() {
            guard self.itemProvider.canLoadObject(ofClass: UIImage.self) else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    loadInPlaceFile()
                }
                return
            }

            self.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                guard let image = image as? UIImage else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        loadInPlaceFile()
                    }
                    return
                }
                imageDidLoaded(image: image, url: nil)
            }
        }
                
        
        func loadItem() {
            self.itemProvider.loadItem(forTypeIdentifier: type.description, options: nil) { item, error in
                if let url = item as? URL, let image = UIImage(contentsOfFile: url.path) {
                    imageDidLoaded(image: image, url: url)
                } else if let image = item as? UIImage {
                    imageDidLoaded(image: image, url: nil)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        loadObjectImage()
                    }
                }
            }
        }
        
        loadItem()
    }
    
    private func requestVideo(type: UTType, progress: STImporter.ProgressHandler?, success: @escaping (STImporter.ImportFileInfo) -> Void, failure: @escaping (IError) -> Void) {
        self.itemProvider.loadInPlaceFileRepresentation(forTypeIdentifier: type.description) { url, isInPlace, error in
            guard let url = url else {
                failure(STImporter.ImporterError.fileNotSupport)
                return
            }
            let asset = AVAsset(url: url)
            let duration = asset.duration.seconds
            let thumbnailTime = min(duration, 0.3)
            guard let thumbnailData = try? asset.generateThumbnailFromAsset(forTime: thumbnailTime).thumbnailData, let size = FileManager.default.fileSize(url: url), let headerFileType = type.headerFileType else {
                failure(STImporter.ImporterError.cantCreateFileThumbnail)
                return
            }
            let date = Date()
            let info = STImporter.ImportFileInfo(oreginalUrl: url, thumbImage: thumbnailData, fileType: headerFileType, duration: duration, fileSize: size, creationDate: date, modificationDate: date, freeBuffer: nil)
            success(info)
        }

    }
        
    private func calculateType(for itemProvider: NSItemProvider) -> UTType? {
        let supportTypes = self.calculateSupportTypes()
        for (_, tTypes) in supportTypes {
            for tType in tTypes {
                guard itemProvider.registeredTypeIdentifiers.contains(tType.description) else {
                    continue
                }
                return tType
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
    
    public class AlbumItemProviderImportable: IItemProviderImportable, AlbumFileImportable {
        
        public let album: STLibrary.Album
        public let itemProvider: NSItemProvider
       
        public init(itemProvider: NSItemProvider, album: STLibrary.Album) {
            self.itemProvider = itemProvider
            self.album = album
        }
    }
        
}
