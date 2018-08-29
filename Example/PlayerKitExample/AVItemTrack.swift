//
//  AVItemTrack.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/29.
//

import Foundation
import UIKit
import PlayerKit

struct AVItemTrack: PlayerKit.Track {
    var title: String?
    var subtitle: String?
    var youtubeVideoID: String?
    var streamURL: URL?
    var isVideo: Bool { return false }
    var isValid: Bool { return true }
    var canPlayBackground: Bool { return true }
    var playerType: PlayerType { return PlayerType.normal }
    var appleMusicID: String? { return nil }
    var spotifyURI: String? { return nil }
    func loadThumbnailImage(completeHandler: @escaping (UIImage?) -> Void) {
        completeHandler(nil)
    }
    
    func loadArtworkImage(completeHandler: @escaping (UIImage?) -> Void) {
        completeHandler(nil)
    }
    init(title: String, channelName: String, streamURL: URL) {
        self.title     = title
        self.subtitle  = channelName
        self.streamURL = streamURL
    }
}
