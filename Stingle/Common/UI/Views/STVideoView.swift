//
//  STVideoView.swift
//  Stingle
//
//  Created by Khoren Asatryan on 5/19/21.
//

import UIKit
import AVKit

class STVideoView: UIView {
    
    weak private(set) var stPlayer: STPlayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override var contentMode: UIView.ContentMode {
        didSet {
            switch self.contentMode {
            case .scaleToFill, .scaleAspectFill:
                self.videoGravity = .resizeAspectFill
            default:
                self.videoGravity = .resizeAspect
            }
        }
    }
        
    override public class var layerClass: Swift.AnyClass {
        return AVPlayerLayer.self
    }
    
    var videoRect: CGRect {
        return self.playerLayer.videoRect
    }

    var videoSize: CGSize {
        return self.player?.currentItem?.asset.videoSize() ?? self.player?.currentItem?.presentationSize ?? .zero
    }
    
    var ratioAspect: CGFloat {
        let size = self.videoSize
        return size.height == .zero ? 0 : size.width / size.height
    }
    
    var isReadyForDisplay: Bool {
        return self.playerLayer.isReadyForDisplay
    }
    
    var playerLayer: AVPlayerLayer {
        get {
            return (self.layer as! AVPlayerLayer)
        }
    }
    
    var player: AVPlayer? {
        set{
            self.playerLayer.player = newValue
        } get {
            return self.playerLayer.player
        }
    }
    
    var videoGravity: AVLayerVideoGravity {
        set {
            self.playerLayer.videoGravity = newValue
        } get {
            return self.playerLayer.videoGravity
        }
    }
    
    func setPlayer(player: STPlayer?) {
        self.stPlayer = player
        self.player = player?.player
    }
    
    //MARK: - Private func
    
    private func setup() {
    }

}

extension AVAsset {
    
    func videoSize() -> CGSize? {
        guard let track = self.tracks(withMediaType: AVMediaType.video).first else {
            return nil
        }
        let size = track.naturalSize
        let txf = track.preferredTransform
        let realVidSize = size.applying(txf)
        return realVidSize
    }

}
