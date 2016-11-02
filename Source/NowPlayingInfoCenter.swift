//
//  NowPlayingInfoCenter.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 7/13/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import MediaPlayer
import SDWebImage

open class NowPlayingInfoCenter: PlayerObserver {
    var player: Player

    open var defaultThumbImage: UIImage? {
        return UIImage(named: "default_thumb")
    }

    public init(player: Player) {
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

    func updateMPNowPlaylingInfoCenter(_ player: Player) {
        guard let track = player.currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        guard let duration = player.avPlayer?.currentItem?.duration else { return }
        guard let elapsedTime = player.avPlayer?.currentTime() else { return }
        let infoCenter = MPNowPlayingInfoCenter.default()
        var info: [String:AnyObject]                      = [:]
        info[MPMediaItemPropertyTitle]                    = track.title as AnyObject?
        info[MPMediaItemPropertyPlaybackDuration]         = CMTimeGetSeconds(duration) as AnyObject?
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(elapsedTime) as AnyObject?
        if let url = track.artworkUrl {
            let imageManager = SDWebImageManager()
            let _ = imageManager.imageDownloader?.downloadImage(
                with: url as URL!,
                options: SDWebImageDownloaderOptions.highPriority,
                progress: {receivedSize, expectedSize, url in }) { (image, data, error, finished) -> Void in
                    let albumArt                     = MPMediaItemArtwork(image: image!)
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
