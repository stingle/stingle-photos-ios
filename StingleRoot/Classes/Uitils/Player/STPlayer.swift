//
//  STPlayer.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import AVKit

public protocol IPlayerObservers: AnyObject {
    func player(player: STPlayer, didChange time: TimeInterval)
    func player(player: STPlayer, didChange status: STPlayer.Status)
    func player(player: STPlayer, didChange state: STPlayer.State)
    func player(player: STPlayer, didChange isMuted: Bool)
    func player(player: STPlayer, didChange volume: Float)
    func player(player: STPlayer, didChangeFirstLoaded: Bool)
    func player(player: STPlayer, didChange error: STPlayer.PlayerError)
}

public extension IPlayerObservers {
    func player(player: STPlayer, didChange time: TimeInterval) {}
    func player(player: STPlayer, didChange status: STPlayer.Status) {}
    func player(player: STPlayer, didChange state: STPlayer.State) {}
    func player(player: STPlayer, didChange isMuted: Bool) {}
    func player(player: STPlayer, didChange volume: Float) {}
    func player(player: STPlayer, didChangeFirstLoaded: Bool) {}
    func player(player: STPlayer, didChange error: STPlayer.PlayerError) {}
}

public class STPlayer: NSObject {
    
    public let player = AVPlayer()
    
    private(set) var file: ILibraryFile?
    
    private var assetResourceLoader: STAssetResourceLoader?
    private let dispatchQueue = DispatchQueue(label: "Player.Queue", attributes: .concurrent)
    private let observers = STObserverEvents<IPlayerObservers>()
    
    private(set) var state: State = .stopped
    private(set) var status: Status = .stopped
    private(set) var isFirstLoaded: Bool = true
    private(set) var isAddedObserver = false
    
    private var observerToken: Any?

    // Smooth-scrubbing state: while a seek is in flight we don't start another, we
    // just remember the latest target (`chaseTime`) and seek to it once the current
    // one finishes. Prevents flooding AVPlayer during a drag.
    private var isSeekInProgress = false
    private var chaseTime: CMTime = .invalid

    // When a remote file is played from the network (not yet on disk) we kick off a
    // one-time full-file download so the encrypted original lands in the local cache.
    // Guarded so repeated `play()` calls (pause/resume, seek-to-start) enqueue once
    // per file; reset whenever a new file becomes current.
    private var didStartCaching = false

    // Sticky: becomes true the first time the current item actually renders frames
    // (`timeControlStatus == .playing`); reset when a new file becomes current. Used
    // to decide whether a finished cache download may swap the live item to the local
    // file — once playback has begun we must NOT swap (it would restart from zero).
    private var hasStartedPlayback = false

    // Caching is deferred until the user has actually been watching for a beat, so the
    // full-file cache download (a) doesn't race the stream for first-frame bandwidth and
    // (b) is skipped entirely when the user is rapidly skimming through videos. After
    // first frame we wait `cacheStartSettleDelay`; if still playing the same file, we
    // cache. A stuck stream that never reaches first frame is covered by the longer
    // `cacheStartFallbackDelay`, which then lets the rescue swap recover it from local.
    private let cacheStartSettleDelay: TimeInterval = 3
    private let cacheStartFallbackDelay: TimeInterval = 10

    public override init() {
        super.init()
        STApplication.shared.downloaderManager.videoCacheDownloader.add(self)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as AnyObject? === self.player {
            if keyPath == "timeControlStatus" {
                self.updateStatus()
            }
        } else if object as AnyObject? === self.player.currentItem {
            if keyPath == "status" {
                self.updateStatus()
            }
        }
    }
    
    //MARK: - Private
    
    private func addAllEvents() {
        self.removeAllEvents()
        self.addNotifications()
        self.addObserverTime()
    }
    
    private func addObserverTime(oldItem: AVPlayerItem? = nil) {
        guard let currentItem = self.player.currentItem, self.observerToken == nil else {
            return
        }
        self.player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        currentItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        let interval = CMTimeMake(value: 1, timescale: 1)
        self.observerToken = self.player.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] (time) in
            self?.didChangeTime(time: time)
            if self?.player.currentItem?.status == .readyToPlay {
                self?.change(firstLoaded: true)
            }
        })
        self.isAddedObserver = true
    }
    
    private func removeAllEvents() {
        guard self.isAddedObserver else {
            return
        }
        self.isAddedObserver = false
        if let observerToken = self.observerToken {
            self.player.currentItem?.removeObserver(self, forKeyPath: "status", context: nil)
            self.player.removeTimeObserver(observerToken)
            self.observerToken = nil
            self.player.removeObserver(self, forKeyPath: "timeControlStatus")
            self.player.pause()
            NotificationCenter.default.removeObserver(self)
        }
    }
            
    private func addNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    private func updateStatus() {
        var myStatus = self.status
        guard self.player.currentItem != nil else {
            return myStatus = .stopped
        }
        switch self.player.timeControlStatus {
        case .paused:
            myStatus = .paused
        case .waitingToPlayAtSpecifiedRate:
            myStatus = .buffering
        case .playing:
            myStatus = .playing
        @unknown default:
            break
        }
        DispatchQueue.main.async {
            if myStatus == .playing {
                self.hasStartedPlayback = true
                // Playback is healthy — cache after a short "is the user actually watching
                // this?" settle, so skimming quickly through videos doesn't enqueue them all.
                self.scheduleCacheDownloadAfterSettle()
            }
            if myStatus != self.status {
                self.change(status: myStatus)
            }
        }
    }
    
    @objc private func playerDidFinishPlaying(note: Notification) {
        guard let object = note.object as? AVPlayerItem, object == self.player.currentItem else {
            return
        }
        self.change(state: .end)
    }
    
    private func didChangeTime(time: CMTime) {
        self.didChange(time: time.seconds)
    }
    
    private func replaceCurrentFile(file: ILibraryFile) {
        guard let fileHeader = file.decryptsHeaders.file else {
            return
        }
        self.removeAllEvents()
        self.file = file
        self.didStartCaching = false
        self.hasStartedPlayback = false
        let resourceLoader = STAssetResourceLoader(file: file, header: fileHeader)
        self.assetResourceLoader = resourceLoader
        let assetKeys = ["playable","hasProtectedContent"]
        let item = AVPlayerItem(asset: resourceLoader.asset, automaticallyLoadedAssetKeys: assetKeys)
        self.player.replaceCurrentItem(with: item)
    }

    // After first frame, wait a beat before caching: if the user skips on before the
    // settle delay, the video is never enqueued — so skimming through a feed of videos
    // doesn't queue them all for download. Only kept if still playing the same file.
    private func scheduleCacheDownloadAfterSettle() {
        guard !self.didStartCaching, let fileName = self.file?.file else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + self.cacheStartSettleDelay) { [weak self] in
            guard let self = self,
                  !self.didStartCaching,
                  self.state == .playing,
                  self.file?.file == fileName else {
                return
            }
            self.cacheCurrentFileIfNeeded()
        }
    }

    // Persist the currently-playing remote file into the local encrypted cache via the
    // dedicated `videoCacheDownloader` (single-concurrency, so caches never pile up and
    // starve the foreground stream). It writes the encrypted original to
    // `…/server/oreginals` (the same path `LocaleReader` reads from); the cache
    // downloader's `didEndDownload` then lets this player swap to local playback for a
    // stalled stream, and every later open is instant instead of re-streaming. No-op
    // when already local or already enqueued. The download lives on the shared cache
    // downloader, so it finishes even if this player (and its viewer) is torn down.
    private func cacheCurrentFileIfNeeded() {
        guard STAppSettings.current.advanced.autoCacheVideos else {
            return
        }
        guard let file = self.file,
              let assetResourceLoader = self.assetResourceLoader,
              !assetResourceLoader.isLocalPlaying,
              !self.didStartCaching else {
            return
        }
        self.didStartCaching = true
        // Silent: caching is automatic, so it must not raise any download progress bar.
        // The player still gets the terminal `didEndDownload` and may swap to local.
        STApplication.shared.downloaderManager.videoCacheDownloader.download(files: [file], showsProgress: false)
    }

    // Backstop for a stream that never produces a first frame: if playback still hasn't
    // begun after `cacheStartFallbackDelay`, start caching so the finished download can
    // swap the stalled item to the reliable local file.
    private func scheduleCacheDownloadFallback() {
        guard let fileName = self.file?.file else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + self.cacheStartFallbackDelay) { [weak self] in
            guard let self = self,
                  !self.didStartCaching,
                  self.state == .playing,
                  self.file?.file == fileName else {
                return
            }
            self.cacheCurrentFileIfNeeded()
        }
    }

}


public extension STPlayer {
    
    var duration: TimeInterval {
        guard let duration = self.player.currentItem?.duration.seconds, !duration.isNaN else {
            return .zero
        }
        return duration
    }
    
    var currentTime: TimeInterval {
        guard let seconds = self.player.currentItem?.currentTimeSeconds else {
            return 0
        }
        return seconds
    }
    
    var isMuted: Bool {
        set {
            self.player.isMuted = newValue
            self.didChangeIsMuted()
        } get {
            return self.player.isMuted
        }
    }
    
    var volume: Float {
        set {
            self.player.volume = newValue
            self.didChangeVolume()
        } get {
            return self.player.volume
        }
    }
    
    func seek(currentTime: TimeInterval) {
        guard self.player.currentItem != nil else {
            return
        }
        self.chaseTime = CMTime(seconds: currentTime, preferredTimescale: 600)
        if !self.isSeekInProgress {
            self.seekToChaseTime()
        }
    }

    private func seekToChaseTime() {
        guard self.player.currentItem?.status == .readyToPlay else {
            self.isSeekInProgress = false
            return
        }
        self.isSeekInProgress = true
        let target = self.chaseTime
        // A small tolerance keeps scrubbing responsive (snap to a nearby sync sample)
        // instead of decoding to an exact frame on every drag of a streamed asset.
        let tolerance = CMTime(seconds: 0.5, preferredTimescale: 600)
        self.player.seek(to: target, toleranceBefore: tolerance, toleranceAfter: tolerance) { [weak self] _ in
            guard let weakSelf = self else { return }
            if weakSelf.chaseTime == target {
                weakSelf.isSeekInProgress = false
            } else {
                weakSelf.seekToChaseTime()
            }
        }
    }
    
    func replaceCurrentItem(with file: ILibraryFile?) {
        self.file = file
        guard let file = file else {
            self.player.replaceCurrentItem(with: nil)
            return
        }
        self.replaceCurrentFile(file: file)
    }
    
    func play(file: ILibraryFile?) {
        self.replaceCurrentItem(with: file)
        self.play()
    }
    
    func play() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            STLogger.log(error: error)
        }
        
        if self.state == .end && (self.duration - self.currentTime) < 1 {
            self.player.currentItem?.seek(to: .zero, completionHandler: nil)
        }
        self.isMuted = false
        self.addAllEvents()
        self.player.play()
        self.change(state: .playing)
        self.scheduleCacheDownloadFallback()
    }
    
    func pause() {
        self.player.pause()
        self.change(state: .paused)
    }
    
    func stop() {
        self.removeAllEvents()
        self.replaceCurrentItem(with: nil)
        self.player.replaceCurrentItem(with: nil)
        self.change(status: .stopped)
        self.change(state: .stopped)
    }
    
}

fileprivate extension STPlayer {
    
    func didChange(time: TimeInterval) {
        for object in self.observers.objects {
            object.player(player: self, didChange: time)
        }
    }
    
    func change(status: Status) {
        if self.status != status {
            self.status = status
            self.didChangeStatus()
        }
    }
    
    func didChangeStatus() {
        for object in self.observers.objects {
            object.player(player: self, didChange: self.status)
        }
    }
    
    func change(state: State) {
        if self.state != state {
            self.state = state
            self.didChangeState()
        }
    }
    
    func change(firstLoaded: Bool) {
        if self.isFirstLoaded != firstLoaded {
            self.isFirstLoaded = firstLoaded
            self.didChangeFirstLoaded()
        }
    }
    
    func didChangeState() {
        for object in self.observers.objects {
            object.player(player: self, didChange: self.state)
        }
    }
    
    func change(isMuted: Bool) {
        if self.isMuted != isMuted {
            self.isMuted = isMuted
            self.didChangeIsMuted()
        }
    }
    
    func didChangeIsMuted() {
        for object in self.observers.objects {
            object.player(player: self, didChange: self.isMuted)
        }
    }
    
    func change(volume: Float) {
        if self.volume != volume {
            self.volume = volume
            self.didChangeVolume()
        }
    }
    
    func didChangeVolume() {
        for object in self.observers.objects {
            object.player(player: self, didChange: self.volume)
        }
    }
    
    func didChange(error: PlayerError) {
        for object in self.observers.objects {
            object.player(player: self, didChange: error)
        }
    }
    
    func didChangeFirstLoaded() {
        for object in self.observers.objects {
            object.player(player: self, didChangeFirstLoaded: self.isFirstLoaded)
        }
    }
    
}

extension STPlayer: STFileDownloaderObserver {
    
    public func downloader(didEndDownload downloader: STDownloaderManager.FileDownloader, source: IDownloaderSource) {
        guard let assetResourceLoader = self.assetResourceLoader, !assetResourceLoader.isLocalPlaying else {
            return
        }
        guard let file = source.asLibraryFile(), file.file == self.file?.file, file.dbSet == self.file?.dbSet else {
            return
        }
        // The cache download finished while we were still streaming this file.
        // Only swap the live item over to the now-local file if playback hasn't
        // begun yet — swapping creates a fresh AVPlayerItem at zero, so doing it
        // mid-playback would visibly reload and restart from the beginning. Once
        // frames are on screen we leave the network stream running to the end and
        // let the cached file serve the *next* open.
        guard self.state == .playing, !self.hasStartedPlayback else {
            return
        }
        // Download often wins the race against the network item becoming ready (and
        // the network item sometimes never readies — the "stuck until I pause/play"
        // case). Switch to the reliable local file and start it. Preserve a pre-play
        // scrub position if the user dragged the slider while it was still buffering.
        let currentTime = self.currentTime
        self.replaceCurrentFile(file: file)
        if currentTime > 0 {
            self.seek(currentTime: currentTime)
        }
        self.play()
    }
    
}

public extension STPlayer {
    
    func addObserver(deleagte: IPlayerObservers) {
        self.observers.addObject(deleagte)
    }

    func removeObserver(deleagte: IPlayerObservers) {
        self.observers.removeObject(deleagte)
    }

    var isStoped: Bool {
        return self.status == .stopped
    }

    var isBuffering: Bool {
        return self.status == .buffering
    }

    var isPlaying: Bool {
        return self.status == .playing
    }

    var isPaused: Bool {
        return self.status == .paused
    }

    var isCompleted: Bool {
        return self.status == .completed
    }
    
}

public extension STPlayer {
    
    enum PlayerError: IError {
        case error(error: Error)
        
        public var message: String {
            switch self {
            case .error(let error):
                if let error = error as? IError {
                    return error.message
                }
                return error.localizedDescription
            }
        }
        
    }
    
    enum Status : Int {
        case stopped = 0
        case buffering
        case playing
        case paused
        case completed
    }

    enum State: Int {
        case paused
        case playing
        case end
        case stopped
    }
    
}

extension AVPlayerItem {
    
    var url: URL? {
        return (self.asset as? AVURLAsset)?.url
    }
    
    var currentTimeSeconds: TimeInterval {
        let seconds = self.currentTime().seconds
        guard !seconds.isNaN else {
            return 0
        }
        return seconds
    }
    
}
