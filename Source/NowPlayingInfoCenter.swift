//
//  NowPlayingInfoCenter.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 7/13/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import MediaPlayer
import SDWebImage

open class NowPlayingInfoCenter: QueuePlayerObserver {
    var player: QueuePlayer

    open var defaultThumbImage: UIImage? {
        return UIImage(named: "default_thumb")
    }

    public init(player: QueuePlayer) {
        self.player = player
    }

    override open func listen(_ event: Event) {
        switch event {
        case .timeUpdated:              updateMPNowPlaylingInfoCenter(player)
        case .didPlayToEndTime:         updateMPNowPlaylingInfoCenter(player)
        case .statusChanged:            updateMPNowPlaylingInfoCenter(player)
        case .trackSelected(_, _, _):   updateMPNowPlaylingInfoCenter(player)
        case .trackUnselected(_, _, _): updateMPNowPlaylingInfoCenter(player)
        default:                        break
        }
    }

    func updateMPNowPlaylingInfoCenter(_ player: QueuePlayer) {
        guard let track = player.currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        guard let i = player.playingInfo else { return }
        let infoCenter = MPNowPlayingInfoCenter.default()
        var info: [String:AnyObject]                      = [:]
        info[MPMediaItemPropertyTitle]                    = track.title as AnyObject?
        info[MPMediaItemPropertyPlaybackDuration]         = i.duration as AnyObject?
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = i.elapsedTime as AnyObject?
        if let url = track.artworkURL {
            let imageManager = SDWebImageManager()
            let _ = imageManager.loadImage(with: url as URL!, options: .highPriority, progress: {receivedSize, expectedSize, url in }) { (image, data, error, cacheType, finished, url) -> Void in
                    guard let img = image else { return }
                    let albumArt                     = MPMediaItemArtwork(image: img)
                    info[MPMediaItemPropertyArtwork] = albumArt
                    infoCenter.nowPlayingInfo        = info
            }
            return
        }
        if let image = defaultThumbImage {
            let albumArt                     = MPMediaItemArtwork(image: image)
            info[MPMediaItemPropertyArtwork] = albumArt
        }
        infoCenter.nowPlayingInfo = info
    }
}
