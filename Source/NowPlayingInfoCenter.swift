//
//  NowPlayingInfoCenter.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 7/13/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import MediaPlayer
import WebImage

public class NowPlayingInfoCenter: PlayerObserver {
    var player: Player

    public var defaultThumbImage: UIImage? {
        return UIImage(named: "default_thumb")
    }

    public init(player: Player) {
        self.player = player
    }

    override public func listen(event: Event) {
        switch event {
        case .TimeUpdated:              updateMPNowPlaylingInfoCenter(player)
        case .DidPlayToEndTime:         updateMPNowPlaylingInfoCenter(player)
        case .StatusChanged:            updateMPNowPlaylingInfoCenter(player)
        case .TrackSelected(_, _, _):   updateMPNowPlaylingInfoCenter(player)
        case .TrackUnselected(_, _, _): updateMPNowPlaylingInfoCenter(player)
        default:                        break
        }
    }

    func updateMPNowPlaylingInfoCenter(player: Player) {
        guard let track = player.currentTrack else {
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
            return
        }
        guard let duration = player.avPlayer?.currentItem?.duration else { return }
        guard let elapsedTime = player.avPlayer?.currentTime() else { return }
        let infoCenter = MPNowPlayingInfoCenter.defaultCenter()
        var info: [String:AnyObject]                      = [:]
        info[MPMediaItemPropertyTitle]                    = track.title
        info[MPMediaItemPropertyPlaybackDuration]         = CMTimeGetSeconds(duration)
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(elapsedTime)
        if let url = track.artworkUrl {
            let imageManager = SDWebImageManager()
            imageManager.downloadImageWithURL(
                url,
                options: SDWebImageOptions.HighPriority,
                progress: {receivedSize, expectedSize in }) { (image, error, cacheType, finished, url) -> Void in
                    let albumArt                     = MPMediaItemArtwork(image: image)
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