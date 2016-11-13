//
//  PlaylistQueue.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/26/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import Foundation

open class PlaylistQueue: NSObject {
    open internal(set) var player: Player?
    open fileprivate(set) var playlists: [Playlist] = []
    public init(playlists: [Playlist]) {
        self.playlists = playlists
    }
    open func enqueue(_ playlist: Playlist) {
        if playlist.tracks.count > 0 {
            self.playlists.append(playlist)
        }
    }
    open func indexOf(_ playlist: Playlist) -> Int? {
        for i in 0..<playlists.count {
            if playlist.id == playlists[i].id {
                return i
            }
        }
        return nil
    }
    open func trackUpdated(_ track: Track) {
        guard let playlistQueue = player?.playlistQueue, playlistQueue == self else { return }
        guard let nextTrack = player?.nextTrack else { return }
        if nextTrack.streamURL == track.streamURL {
            player?.nextTrackAdded()
        }
    }
}
