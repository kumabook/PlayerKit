//
//  PlaylistQueue.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/26/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import Foundation

public class PlaylistQueue: NSObject {
    public private(set) var playlists: [Playlist] = []
    public init(playlists: [Playlist]) {
        self.playlists = playlists
    }
    public func enqueue(playlist: Playlist) {
        if playlist.tracks.count > 0 {
            self.playlists.append(playlist)
        }
    }
    public func indexOf(playlist: Playlist) -> Int? {
        for i in 0..<playlists.count {
            if playlist.id == playlists[i].id {
                return i
            }
        }
        return nil
    }
}
