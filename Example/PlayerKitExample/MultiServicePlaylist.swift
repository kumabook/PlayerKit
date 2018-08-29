//
//  MultiServicePlaylist.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/28.
//

import Foundation
import PlayerKit

struct MultiServicePlaylist: PlayerKit.Playlist {
    var id: String
    var tracks: [Track]
    var validTracksCount: Int {
        return tracks.count
    }

    init(id: String, tracks: [Track]) {
        self.id = id
        self.tracks = tracks
    }
}
