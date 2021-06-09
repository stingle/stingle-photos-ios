//
//  STPlayer.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import AVKit

class STPlayer {
    
    let player = AVPlayer()
    
    private(set) var file: STLibrary.File?
    
    private var assetResourceLoader: STAssetResourceLoader?
    private let dispatchQueue = DispatchQueue(label: "Player.Queue", attributes: .concurrent)
    
    
    func replaceCurrentItem(with file: STLibrary.File?) {
        self.file = file

        guard let file = file, let fileHeader = file.decryptsHeaders.file else {
            self.player.replaceCurrentItem(with: nil)
            return
        }

        let url = file.fileOreginalUrl
        let resourceLoader = STAssetResourceLoader(with: url!, header: fileHeader, fileExtension: nil)
        self.assetResourceLoader = resourceLoader
        let item = AVPlayerItem(asset: resourceLoader.asset, automaticallyLoadedAssetKeys: nil)
        self.player.replaceCurrentItem(with: item)
    }
    
    func play(file: STLibrary.File?) {
        self.replaceCurrentItem(with: file)
        self.play()
    }
    
    func play() {
        self.player.play()
    }
    
}


extension STPlayer {
    
    var duration: TimeInterval {
        guard let duration = self.player.currentItem?.duration.seconds, !duration.isNaN else {
            return .zero
        }
        return duration
    }
    
    
    func seek(currentTime: TimeInterval) {
        let time = CMTime(seconds: currentTime, preferredTimescale: 1)
        self.player.seek(to: time)
    }
    
}
