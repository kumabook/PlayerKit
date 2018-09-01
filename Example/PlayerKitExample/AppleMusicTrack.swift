//
//  AppleMusicTrack.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/09/01.
//

import Foundation
import Cider
import PlayerKit
import SDWebImage
// Cider.Track: PlayerKit.Track
extension Resource : PlayerKit.Track where AttributesType == TrackAttributes,
                                        RelationshipsType == TrackRelationships {
    public var title: String? {
        return attributes?.name
    }
    
    public var subtitle: String? {
        return attributes?.artistName
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
        if AppleMusicClient.shared.countryCode != nil  {
            return .appleMusic
        }
        return .normal
    }
    
    public var streamURL: URL? {
        guard let url = attributes?.previews.first?.url else { return nil }
        return URL(string: url)
    }
    
    public var appleMusicID: String? {
        return id
    }
    
    public var spotifyURI: String? {
        return nil
    }
    
    public var youtubeVideoID: String? {
        return nil
    }
    
    public func loadThumbnailImage(completeHandler: @escaping (UIImage?) -> Void) {
        if let url = self.attributes?.artwork.url(forWidth: 200) {
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
        if let url = self.attributes?.artwork.url(forWidth: 800) {
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
