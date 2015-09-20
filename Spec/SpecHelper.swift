//
//  TestTrack.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 9/20/15.
//  Copyright © 2015 kumabook. All rights reserved.
//

import UIKit
import PlayerKit

class SpecHelper {
}

class TestTrack: PlayerKit.Track {
    var title:        String? { return "test track" }
    var streamUrl:    NSURL?  { return NSURL(string: "http://logical-oscillator.github.io/trial_tracks/1.mp3") }
    var thumbnailUrl: NSURL?  { return nil }
    var isVideo:      Bool    { return false }
}

class TestPlaylist: PlayerKit.Playlist {
    var id:               String { return "test" }
    var tracks:           [Track] { return [TestTrack()] }
    var validTracksCount: Int { return 1 }
}

class TestObserver: PlayerKit.PlayerObserver {
    var timeUpdatedCount:               Int = 0
    var didPlayToEndTimeCount:          Int = 0
    var statusChangedCount:             Int = 0
    var trackSelectedCount:             Int = 0
    var trackUnselectedCount:           Int = 0
    var previousPlaylistRequestedCount: Int = 0
    var nextPlaylistRequestedCount:     Int = 0
    var errorOccuredCount:              Int = 0

    override func timeUpdated() {
        timeUpdatedCount++
    }
    override func didPlayToEndTime() {
        didPlayToEndTimeCount++
    }
    override func statusChanged() {
        statusChangedCount++
    }
    override func trackSelected(track: Track, index: Int, playlist: Playlist) {
        trackSelectedCount++
    }
    override func trackUnselected(track: Track, index: Int, playlist: Playlist) {
        trackUnselectedCount++
    }
    override func previousPlaylistRequested() {
        previousPlaylistRequestedCount++
    }
    override func nextPlaylistRequested() {
        nextPlaylistRequestedCount++
    }
    override func errorOccured() {
        errorOccuredCount++
    }
}