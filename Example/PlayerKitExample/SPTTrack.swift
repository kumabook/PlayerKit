//
//  SPTTrack.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/09/01.
//

import Foundation
import SDWebImage
import Spotify
import PlayerKit

extension SPTTrack: Track {
    public var title: String? {
        return name
    }
    
    public var subtitle: String? {
        return (artists?.first as? SPTAlbum)?.name
    }
    
    public var isVideo: Bool {
        return false
    }
    
    public var isValid: Bool {
        return true
    }
    
    public var canPlayBackground: Bool {
        return true
    }
    
    public var playerType: PlayerType {
        return SpotifyAPIClient.isPremiumUser ? .spotify : .normal
    }
    
    public var streamURL: URL? {
        return previewURL
    }
    
    public var appleMusicID: String? {
        return nil
    }
    
    public var spotifyURI: String? {
        return uri?.absoluteString
    }
    
    public var youtubeVideoID: String? {
        return nil
    }
    
    public func loadThumbnailImage(completeHandler: @escaping (UIImage?) -> Void) {
        if let url = album?.smallestCover.imageURL {
            SDWebImageManager.shared().loadImage(with: url,
                                                 options: .highPriority,
                                                 progress: {receivedSize, expectedSize, url in }) { (image, data, error, cacheType, finished, url) -> Void in
                                                    completeHandler(image)
            }
        } else {
            completeHandler(nil)
        }
    }
    
    public func loadArtworkImage(completeHandler: @escaping (UIImage?) -> Void) {
        if let url = album?.largestCover.imageURL {
            SDWebImageManager.shared().loadImage(with: url,
                                                 options: .highPriority,
                                                 progress: {receivedSize, expectedSize, url in }) { (image, data, error, cacheType, finished, url) -> Void in
                                                    completeHandler(image)
            }
        } else {
            completeHandler(nil)
        }
    }
}
