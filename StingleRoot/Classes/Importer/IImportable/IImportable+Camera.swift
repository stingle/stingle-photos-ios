//
//  IImportable+Camera.swift
//  StingleRoot
//
//  Importable for files produced by the native camera. Unlike the PHAsset /
//  item-provider importables, the camera already owns the plaintext file, its
//  type, duration, thumbnail and creation date, so requestData() is synchronous
//  and never re-decodes the media.
//

import Foundation

extension STImporter {

    public class CameraFileImportable: IImportableGaleryFile {

        public typealias File = STLibrary.GaleryFile

        public let result: STCaptureResult

        public init(result: STCaptureResult) {
            self.result = result
        }

        public func requestData(in queue: DispatchQueue?,
                                progress: STImporter.ProgressHandler?,
                                success: @escaping (STImporter.ImportFileInfo) -> Void,
                                failure: @escaping (IError) -> Void) {

            func resolve(_ block: @escaping () -> Void) {
                if let queue { queue.async(execute: block) } else { block() }
            }

            let url = self.result.fileURL
            guard let size = FileManager.default.fileSize(url: url) else {
                resolve { failure(STImporter.ImporterError.fileNotSupport) }
                return
            }

            // Delete the per-capture temp folder once the importer is done with it.
            let folder = url.deletingLastPathComponent()
            let info = STImporter.ImportFileInfo(oreginalUrl: url,
                                                 thumbImage: self.result.thumbnailData,
                                                 fileType: self.result.fileType,
                                                 duration: self.result.duration,
                                                 fileSize: size,
                                                 creationDate: self.result.creationDate,
                                                 modificationDate: self.result.creationDate) {
                try? FileManager.default.removeItem(at: folder)
            }
            resolve { success(info) }
        }
    }
}
