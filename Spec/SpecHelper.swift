//
//  TestTrack.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 9/20/15.
//  Copyright © 2015 kumabook. All rights reserved.
//

import Foundation
import PlayerKit

class SpecHelper {
}

class TestTrack: PlayerKit.Track {
    public var playerType:   PlayerType = .normal
    public var title:        String? { return "test track" }
    public var subtitle:     String?
    public var artworkURL:   URL?
    public var streamURL:    URL?  { return URL(string: "http://6gical.github.io/trial_tracks/1.mp3") }
    public var thumbnailURL: URL?  { return nil }
    public var isVideo:      Bool    { return false }
    public var isValid:      Bool = true
    public var appleMusicID: String? { return nil }
    public var spotifyURI:   String? { return nil }
}

class TestPlaylist: PlayerKit.Playlist {
    var id:               String { return "test" }
    var tracks:           [Track] { return [TestTrack()] }
    var validTracksCount: Int { return 1 }
}

class TestObserver: PlayerKit.QueuePlayerObserver {
    var timeUpdatedCount:               Int = 0
    var didPlayToEndTimeCount:          Int = 0
    var statusChangedCount:             Int = 0
    var trackSelectedCount:             Int = 0
    var trackUnselectedCount:           Int = 0
    var previousPlaylistRequestedCount: Int = 0
    var nextPlaylistRequestedCount:     Int = 0
    var errorOccuredCount:              Int = 0
    var playlistChangedCount:           Int = 0
    var nextTrackAddedCount:                 Int = 0

    open override func listen(_ event: Event) {
        switch event {
        case .timeUpdated:
            timeUpdatedCount += 1
        case .didPlayToEndTime:
            didPlayToEndTimeCount += 1
        case .statusChanged:
            statusChangedCount += 1
        case .trackSelected(_, _, _):
            trackSelectedCount += 1
        case .trackUnselected(_, _, _):
            trackUnselectedCount += 1
        case .previousPlaylistRequested:
            previousPlaylistRequestedCount += 1
        case .nextPlaylistRequested:
            nextPlaylistRequestedCount += 1
        case .errorOccured:
            errorOccuredCount += 1
        case .playlistChanged:
            playlistChangedCount += 1
        case .nextTrackAdded:
            nextTrackAddedCount += 1
        }
    }
}
