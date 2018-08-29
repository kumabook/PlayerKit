//
//  YouTubeTrack.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/28.
//

import Foundation
import UIKit
import PlayerKit

struct YouTubeTrack: PlayerKit.Track {
    var title: String?
    var subtitle: String?
    var youtubeVideoID: String?
    var isVideo: Bool { return true }
    var isValid: Bool { return true }
    var canPlayBackground: Bool { return true }
    var playerType: PlayerType { return PlayerType.youtube }
    var streamURL: URL? { return nil }
    var appleMusicID: String? { return nil }
    var spotifyURI: String? { return nil }
    func loadThumbnailImage(completeHandler: @escaping (UIImage?) -> Void) {
        completeHandler(nil)
    }
    
    func loadArtworkImage(completeHandler: @escaping (UIImage?) -> Void) {
        completeHandler(nil)
    }
    init(title: String, channelName: String, identifier: String) {
        self.title          = title
        self.subtitle       = channelName
        self.youtubeVideoID = identifier
    }
}
