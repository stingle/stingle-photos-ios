//
//  STCameraImporter.swift
//  StingleRoot
//
//  Bridges camera captures into the encrypt → DB → upload pipeline, reusing the
//  exact path the share extension uses. Lives in StingleRoot so the in-app
//  camera and the LockedCameraCapture extension share it verbatim. Works while
//  the app-lock is engaged: encryption needs only the on-disk public key and
//  uploads ride the existing background URLSession.
//

import Foundation

public final class STCameraImporter {

    public static let shared = STCameraImporter()

    private init() {}

    public typealias Completion = (_ success: Bool) -> Void

    /// Encrypts a single capture and queues it for upload.
    /// Safe to call repeatedly; each capture runs through its own importer.
    @discardableResult
    public func `import`(result: STCaptureResult,
                         responseQueue: DispatchQueue = .main,
                         progress: ((Double) -> Void)? = nil,
                         completion: Completion? = nil) -> Bool {

        guard STApplication.shared.isFileSystemAvailable else {
            // Not logged in / no user record — nothing we can do with the capture.
            try? FileManager.default.removeItem(at: result.fileURL.deletingLastPathComponent())
            responseQueue.async { completion?(false) }
            return false
        }

        let importable = STImporter.CameraFileImportable(result: result)
        let queue = STOperationManager.shared.createQueue(maxConcurrentOperationCount: 1,
                                                          underlyingQueue: STImporter.importerDispatchQueue)
        _ = STImporter.GaleryFileImporter(importFiles: [importable],
                                          operationQueue: queue,
                                          responseQueue: responseQueue,
                                          startHendler: {},
                                          progressHendler: { prog in
            progress?(prog.fractionCompleted)
        }, complition: { files, _ in
            completion?(!files.isEmpty)
        }, uploadIfNeeded: true)
        return true
    }
}
