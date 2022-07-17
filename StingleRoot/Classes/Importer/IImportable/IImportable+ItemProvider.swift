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
                
        self.itemProvider.loadFileRepresentation(forTypeIdentifier: type.description) { [weak self] url, error in
            guard let url = url, url.isFileURL else {
                if let error = error {
                    compled(error: STError.error(error: error))
                } else {
                    compled(error: STImporter.ImporterError.fileNotSupport)
                }
                return
            }
            
            let id = UUID().uuidString
            let fileManager = FileManager.default
            var temporaryDirectory = fileManager.temporaryDirectory
            temporaryDirectory = temporaryDirectory.appendingPathComponent(id)
            let fileFolderURL = temporaryDirectory

            do {
                try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
                temporaryDirectory = temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try fileManager.moveItem(at: url, to: temporaryDirectory)
            } catch {
                try? fileManager.removeItem(at: url)
                try? fileManager.removeItem(at: fileFolderURL)
                compled(error: STError.error(error: error))
                return
            }
 
            self?.requestData(type: type, url: temporaryDirectory, progress: { progress, stop in
                compled(progress, &stop)
            }, success: { importFileInfo in
                compled(importFileInfo: importFileInfo)
            }, failure: { error in
                compled(error: error)
            }, freeBuffer: {
                try? fileManager.removeItem(at: fileFolderURL)
            })
        }
    }
    
    
    private func requestData(type: UTType, url: URL, progress: STImporter.ProgressHandler?, success: @escaping (STImporter.ImportFileInfo) -> Void, failure: @escaping (IError) -> Void, freeBuffer: (() -> Void)?) {
        switch type.headerFileType {
        case .image:
            self.requestImage(type: type, url: url, progress: progress, success: success, failure: failure, freeBuffer: freeBuffer)
        case .video:
            self.requestVideo(type: type, url: url, progress: progress, success: success, failure: failure, freeBuffer: freeBuffer)
        default:
            freeBuffer?()
            failure(STImporter.ImporterError.fileNotSupport)
        }
        
    }
    
    private func requestImage(type: UTType, url: URL, progress: STImporter.ProgressHandler?, success: @escaping (STImporter.ImportFileInfo) -> Void, failure: @escaping (IError) -> Void, freeBuffer: (() -> Void)?) {
        guard let image = UIImage(contentsOfFile: url.path), let thumbnailData = image.thumbnailData, let size = FileManager.default.fileSize(url: url), let headerFileType =  type.headerFileType else {
            freeBuffer?()
            failure(STImporter.ImporterError.fileNotSupport)
            return
        }
        let date = Date()
        let info = STImporter.ImportFileInfo(oreginalUrl: url, thumbImage: thumbnailData, fileType: headerFileType, duration: .zero, fileSize: size, creationDate: date, modificationDate: date, freeBuffer: freeBuffer)
        success(info)
    }
    
    private func requestVideo(type: UTType, url: URL, progress: STImporter.ProgressHandler?, success: @escaping (STImporter.ImportFileInfo) -> Void, failure: @escaping (IError) -> Void, freeBuffer: (() -> Void)?) {
        
        let asset = AVAsset(url: url)
        let duration = asset.duration.seconds
        let thumbnailTime = min(duration, 1)
        
        guard let thumbnailData = try? asset.generateThumbnailFromAsset(forTime: thumbnailTime).thumbnailData, let size = FileManager.default.fileSize(url: url), let headerFileType = type.headerFileType else {
            failure(STImporter.ImporterError.cantCreateFileThumbnail)
            return
        }
        
        let date = Date()
        let info = STImporter.ImportFileInfo(oreginalUrl: url, thumbImage: thumbnailData, fileType: headerFileType, duration: duration, fileSize: size, creationDate: date, modificationDate: date, freeBuffer: freeBuffer)
        success(info)
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
    
        
}


