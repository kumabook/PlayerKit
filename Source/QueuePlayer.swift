//
//  ServicePlayer.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/03/09.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation

public protocol QueuePlayer: class, Observable {
    typealias ObserverType = QueuePlayerObserver
    typealias EventType    = QueuePlayerEvent
    var itemIndex:         Int { get }
    var state:             PlayerState { get set }
    var tracks:            TrackList { get set }
    var trackIndex:        Int { get set }
    var currentTime:       TimeInterval?  { get }
    var currentIndex:      Int?   { get }
    var currentTrack:      Track? { get }
    var previousTrack:     Track? { get }
    var nextTrack:         Track? { get }
    func isSelected(_ trackIndex: Int) -> Bool
    func previous()
    func next()
    func seekToTime(_ time: TimeInterval)
    func nextTrackAdded()
    func play(trackIndex: Int, tracks: TrackList)
    func prepare(_ index: Int, of: TrackList)
    func toggle()
    // should be implement
    var playerType: PlayerType { get }
    func pause()
    func play()
    func preparePlayer()
}

open class QueuePlayerObserver: NSObject, Observer {
    public typealias Event = QueuePlayerEvent
    open func listen(_ event: Event) {
    }
}

public func ==(lhs: QueuePlayerObserver, rhs: QueuePlayerObserver) -> Bool {
    return lhs.isEqual(rhs)
}

public enum QueuePlayerEvent {
    case timeUpdated
    case didPlayToEndTime
    case statusChanged
    case trackSelected(Track, Int)
    case trackUnselected(Track, Int)
    case previousRequested
    case nextRequested;
    case errorOccured
    case nextTrackAdded
}

extension QueuePlayer {
    var currentIndex:      Int? { return trackIndex(itemIndex) }
    func trackIndex(_ index: Int) -> Int? {
        var _indexes: [Int:Int] = [:]
        var c = 0
        for i in 0..<tracks.count {
            if tracks[i].isValid {
                _indexes[c] = i
                c += 1
            }
        }
        if 0 <= index && index < c {
            return _indexes[index]!
        } else {
            return nil
        }
    }
    
    var currentTrack: Track?     {
        if let i = currentIndex {
            if i < tracks.count {
                return tracks[i]
            }
        }
        return nil
    }
    var previousTrack:     Track?     { return trackIndex(itemIndex-1).map { tracks[$0] }}
    var nextTrack:         Track?     { return trackIndex(itemIndex+1).map { tracks[$0] }}
    func isSelected(_ trackIndex: Int) -> Bool { return currentIndex.map { $0 == trackIndex } ?? false }
    func previous() {
        guard let  i = trackIndex(itemIndex-1) else {
            notify(.previousRequested)
            return
        }
        if state.isPlaying {
            let _ = play(trackIndex: i)
        } else {
            prepare(i, of: tracks)
            state = .pause
        }
    }
    func next() {
        guard let i = trackIndex(itemIndex+1) else {
            notify(.nextRequested)
            return
        }
        if state.isPlaying {
            let _ = play(trackIndex: i)
        } else {
            prepare(i, of: tracks)
            state = .pause
        }
    }
    func nextTrackAdded() {
        notify(.nextTrackAdded)
    }

    func prepare(_ index: Int,  of tracks: TrackList) {
        self.tracks     = tracks
        self.trackIndex = index
        if let i = currentIndex, let t = currentTrack {
            notify(.trackUnselected(t, i))
        }
        preparePlayer()
        if let i = currentIndex, let track = currentTrack {
            notify(.trackSelected(track, i))
        }
    }

    func play() {
        play(trackIndex: itemIndex)
    }
    
    //    open func select(_ trackIndex: Int, tracks: TrackList) -> Bool {
    //        return select(trackIndex: trackIndex, tracks: TrackList)
    //    }
    
    func select(trackIndex: Int, tracks: TrackList) -> Bool {
        if self.tracks == tracks && isSelected(trackIndex) {
            return true
        }
        if tracks[trackIndex].isValid  {
            return false
        }
        self.tracks = tracks
        prepare(trackIndex, of: tracks)
        return true
    }
    
    public func toggle() {
        if state.isPlaying {
            pause()
        } else {
            play()
        }
    }
    public func play(trackIndex: Int) {
        return play(trackIndex: trackIndex, tracks: tracks)
    }
    public func play(trackIndex: Int, tracks: TrackList) {
        if self.tracks != tracks || !isSelected(trackIndex) {
            prepare(trackIndex, of: tracks)
        }
        return play()
    }
}
