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
    
    public override init() {
        super.init()
        STApplication.shared.downloaderManager.fileDownloader.add(self)
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
        
        guard let currentItem = self.player.currentItem else {
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
        
        self.file = file
        let resourceLoader = STAssetResourceLoader(file: file, header: fileHeader)
        self.assetResourceLoader = resourceLoader
        let assetKeys = ["playable","hasProtectedContent"]
        let item = AVPlayerItem(asset: resourceLoader.asset, automaticallyLoadedAssetKeys: assetKeys)
        self.player.replaceCurrentItem(with: item)
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
        guard let timescale = self.player.currentItem?.currentTime().timescale else {
            return
        }
        let time = CMTime(seconds: currentTime, preferredTimescale: timescale)
        self.player.seek(to: time)
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
        guard let file = source.asLibraryFile(), file.file == self.file?.file, file.dbSet == self.file?.dbSet else {
            return
        }
                
        let currentTime = self.currentTime
        let isPLaying = self.isPlaying
        self.replaceCurrentFile(file: file)
        self.seek(currentTime: currentTime)
        if isPLaying {
            self.play()
        }
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
