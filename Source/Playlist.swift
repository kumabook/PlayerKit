//
//  Playlist.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/26/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import Foundation

public protocol Playlist {
    var id:               String { get }
    var tracks:           [Track] { get }
    var validTracksCount: Int { get }
}

extension Playlist {
    func createTrackList(with index: Int) -> TrackList {
        let track = tracks[index]
        return TrackList(id: "\(id)-from-\(index)-\(track.playerType)", tracks: [track])
    }
    func createTrackList(from index: Int) -> TrackList {
        var items: [Track] = []
        let type = tracks[index].playerType
        for track in tracks[index..<tracks.count] {
            if track.playerType != type { break }
            items.append(track)
        }
        return TrackList(id: "\(id)-from-\(index)-\(type)", tracks: items)
    }
}
