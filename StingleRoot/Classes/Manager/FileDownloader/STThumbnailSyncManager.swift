//
//  STThumbnailSyncManager.swift
//  StingleRoot
//
//  Background sync of all missing thumbnails into the local cache.
//

import Foundation

public protocol IThumbnailSyncObserver: AnyObject {
    func thumbnailSyncManager(didUpdate manager: STThumbnailSyncManager, state: STThumbnailSyncManager.State)
}

public extension IThumbnailSyncObserver {
    func thumbnailSyncManager(didUpdate manager: STThumbnailSyncManager, state: STThumbnailSyncManager.State) {}
}

/// Walks the whole encrypted catalog (gallery + album files + trash) and downloads the
/// thumbnails that aren't yet in the on-disk cache, so the gallery can render instantly
/// offline. Thumbnails are sealed with `crypto_box_seal`, so only the *public* key is needed
/// to store them — this works while the app-lock is engaged, like the camera path. Progress is
/// surfaced through `IThumbnailSyncObserver` and shown as a row in the sync-status dropdown.
///
/// Two hard-won constraints shape this design:
/// - **Don't collide with the post-sync UI work.** `startSync()` is triggered from
///   `STSyncManager.didEndSync`, which is also when the gallery does its big Core Data reload on
///   the main thread. Kicking off a full-catalog scan right then froze the UI for seconds, so the
///   scan is deferred by `scanStartDelay` and runs at `.utility` QoS.
/// - **Don't poison the cache.** A rate-limited / erroring server can answer a thumbnail request
///   with a JSON error body (HTTP 200), which Alamofire happily writes to the thumbnail's cache
///   path. Every finished download is validated against the Stingle file magic (`SP`); anything
///   that isn't a real encrypted file is deleted (so the next scan retries it) and the rest of the
///   batch is aborted to stop hammering the server.
///
/// Downloads are fed to the underlying `FileDownloader` through a **bounded window** rather than
/// all at once: a library can have tens of thousands of missing thumbnails, and handing the whole
/// list to `download(sources:)` runs a synchronous per-source enqueue loop and floods the main
/// queue with per-source callbacks. The window keeps only `windowSize` requests in flight.
public class STThumbnailSyncManager {

    public struct State: Equatable {
        public let total: Int
        public let completed: Int
        public let isSyncing: Bool

        public var fractionCompleted: Double {
            guard self.total > 0 else { return 0 }
            return Double(self.completed) / Double(self.total)
        }
    }

    // A dedicated downloader instance so thumbnail-sync progress is isolated from the
    // user-initiated original-file downloads on `STApplication.shared.downloaderManager`.
    private let downloader = STDownloaderManager.FileDownloader()
    private let observerEvents = STObserverEvents<IThumbnailSyncObserver>()
    private let scanQueue = DispatchQueue(label: "org.stingle.thumbnailSync.scan", qos: .utility)
    private let validationQueue = DispatchQueue(label: "org.stingle.thumbnailSync.validation", qos: .utility)

    // Max number of thumbnail downloads kept in flight at once (the operation queue itself caps
    // real concurrency at 20; a slightly larger window keeps that queue fed).
    private let windowSize = 30

    // How long to wait after a trigger before scanning, so the first downloads don't burst onto the
    // main thread exactly while the gallery does its post-sync reload. The scan itself now runs on a
    // dedicated context off-main (see `missingThumbnailSources`), so this only has to outlast the
    // gallery's reload, not the (previously main-blocking) scan.
    private static let scanStartDelay: TimeInterval = 1.0

    // Fault catalog rows in chunks during the scan so a big library can't hold the persistent-store
    // lock long enough to stall the main thread.
    private static let fetchBatchSize = 500

    // All of the following are mutated only on the main queue (the downloader fires its
    // callbacks on main and every scan hops back to main before touching them).
    private var pending = [IDownloaderSource]()
    private var pendingIndex = 0
    private var inFlight = 0
    private var total = 0
    private var completed = 0
    private var isSyncing = false
    private var isScanning = false
    private var isAborting = false
    private var needsRescan = false

    public init() {
        self.downloader.add(self)
    }

    public var state: State {
        return State(total: self.total, completed: self.completed, isSyncing: self.isSyncing)
    }

    public func addListener(_ listener: IThumbnailSyncObserver) {
        self.observerEvents.addObject(listener)
    }

    public func removeListener(_ listener: IThumbnailSyncObserver) {
        self.observerEvents.removeObject(listener)
    }

    /// Entry point. Safe to call repeatedly and from any thread; re-triggers that arrive while a
    /// batch is already running are coalesced into a single rescan on completion (so nothing is
    /// double-counted and the same thumbnail isn't enqueued twice).
    public func startSync() {
        DispatchQueue.main.async { [weak self] in
            self?.scheduleScan()
        }
    }

    public func logout() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.downloader.cancelAllOperation()
            self.resetState()
            self.isScanning = false
            self.needsRescan = false
            self.notify()
        }
    }

    // MARK: - Private (scan / queueing — main queue)

    private func scheduleScan() {
        // Only one batch in flight at a time. In-flight thumbnails aren't on disk yet, so
        // scanning again mid-batch would re-detect them as "missing"; defer instead.
        guard !self.isScanning, !self.isSyncing else {
            self.needsRescan = true
            return
        }
        self.isScanning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.scanStartDelay) { [weak self] in
            self?.runScan()
        }
    }

    private func runScan() {
        guard STApplication.shared.isFileSystemAvailable else {
            self.isScanning = false
            self.drainRescanIfNeeded()
            return
        }
        self.scanQueue.async { [weak self] in
            let missing = self?.missingThumbnailSources() ?? []
            DispatchQueue.main.async {
                guard let self else { return }
                self.isScanning = false
                guard !missing.isEmpty else {
                    self.drainRescanIfNeeded()
                    return
                }
                self.pending = missing
                self.pendingIndex = 0
                self.inFlight = 0
                self.total = missing.count
                self.completed = 0
                self.isAborting = false
                self.isSyncing = true
                self.notify()
                self.pumpWindow()
            }
        }
    }

    /// Keeps the in-flight window full. Each `download(sources:[source])` call is cheap; capping
    /// it at `windowSize` is what keeps the main queue responsive on huge libraries.
    private func pumpWindow() {
        while self.inFlight < self.windowSize, self.pendingIndex < self.pending.count {
            let source = self.pending[self.pendingIndex]
            self.pendingIndex += 1
            self.inFlight += 1
            self.downloader.download(sources: [source])
        }
    }

    private func resetState() {
        self.pending = []
        self.pendingIndex = 0
        self.inFlight = 0
        self.total = 0
        self.completed = 0
        self.isSyncing = false
        self.isAborting = false
    }

    private func drainRescanIfNeeded() {
        guard self.needsRescan else { return }
        self.needsRescan = false
        self.scheduleScan()
    }

    private func didProcessOne() {
        self.completed += 1
        self.inFlight -= 1
        self.notify()
        self.pumpWindow()
    }

    /// Stop feeding new downloads; let the in-flight ones drain (they'll mostly error out and
    /// delete themselves too). `didFinished` then resets state and the next sync retries.
    private func abortBatch() {
        guard self.isSyncing, !self.isAborting else { return }
        self.isAborting = true
        self.pending = []
        self.pendingIndex = 0
    }

    private func missingThumbnailSources() -> [IDownloaderSource] {
        guard STApplication.shared.isFileSystemAvailable else { return [] }
        let db = STApplication.shared.dataBase
        let fileSystem = STApplication.shared.fileSystem

        // Read on a dedicated, throwaway context so this full-catalog walk never serializes behind
        // (or stalls) the shared background context that sync writes through. Filter to remote+synced
        // rows in SQLite — only those have a server thumbnail to fetch — instead of pulling the whole
        // catalog and filtering in Swift, and fault in batches so the scan stays off the main thread.
        let context = db.makeReadContext()
        let remoteSynced = NSPredicate(format: "isRemote == YES AND isSynched == YES")
        let batchSize = Self.fetchBatchSize

        var files = [ILibraryFile]()
        files.append(contentsOf: db.galleryProvider.fetchObjects(predicate: remoteSynced, batchSize: batchSize, context: context).map { $0 as ILibraryFile })
        files.append(contentsOf: db.albumFilesProvider.fetchObjects(predicate: remoteSynced, batchSize: batchSize, context: context).map { $0 as ILibraryFile })
        files.append(contentsOf: db.trashProvider.fetchObjects(predicate: remoteSynced, batchSize: batchSize, context: context).map { $0 as ILibraryFile })

        var sources = [IDownloaderSource]()
        var seen = Set<String>()
        for file in files {
            // The predicate guarantees remote+synced, so `fileThumbUrl` resolves to the server thumb.
            guard let thumbUrl = file.fileThumbUrl else { continue }
            guard !fileSystem.isExistFile(file: file, isThumb: true) else { continue }
            let source = STDownloaderManager.FileDownloaderSource(file: file, fileSaveUrl: thumbUrl, isThumb: true)
            guard seen.insert(source.identifier).inserted else { continue }
            sources.append(source)
        }
        return sources
    }

    private func notify() {
        let state = self.state
        self.observerEvents.forEach { $0.thumbnailSyncManager(didUpdate: self, state: state) }
    }

    // MARK: - Cache-poisoning guards

    /// A real Stingle media/thumbnail file starts with the `SP` magic. A rate-limit / error JSON
    /// body (which the server can return with HTTP 200) does not, so we can cheaply tell them apart
    /// by reading the first couple of bytes.
    private static func isValidEncryptedFile(at url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        let expected = STCrypto.Constants.FileBeggining
        let length = STCrypto.Constants.FileBegginingLen
        let data = (try? handle.read(upToCount: length)) ?? Data()
        guard data.count == length else { return false }
        return String(bytes: data, encoding: .utf8) == expected
    }

    private static func removeFile(at url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

extension STThumbnailSyncManager: STFileDownloaderObserver {

    public func downloader(didEndDownload downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource) {
        self.didProcessOne()
        // Validate off-main: if the server handed us an error body instead of an encrypted thumb,
        // drop it so the cache isn't poisoned and abort the rest of the batch (likely rate-limited).
        let url = source.fileSaveUrl
        self.validationQueue.async { [weak self] in
            guard !STThumbnailSyncManager.isValidEncryptedFile(at: url) else { return }
            STThumbnailSyncManager.removeFile(at: url)
            DispatchQueue.main.async { self?.abortBatch() }
        }
    }

    public func downloader(didFailDownload downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource) {
        // A failed transfer can leave a partial file at the cache path; remove it so it isn't
        // mistaken for a valid thumbnail next scan.
        let url = source.fileSaveUrl
        self.validationQueue.async { STThumbnailSyncManager.removeFile(at: url) }
        self.didProcessOne()
    }

    public func downloader(didFinished downloader: STDownloaderManager.FileDownloader) {
        // Authoritative "everything drained" signal: the window kept the downloader busy until
        // `pending` was exhausted, so this only fires at the true end of a batch.
        guard self.isSyncing else { return }
        self.resetState()
        self.notify()
        self.drainRescanIfNeeded()
    }
}
