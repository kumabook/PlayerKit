//  Player.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 3/1/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import AVFoundation

open class PlayerObserver: NSObject, Observer {
    public typealias Event = PlayerEvent
    open func listen(_ event: Event) {
    }
}

public func ==(lhs: PlayerObserver, rhs: PlayerObserver) -> Bool {
    return lhs.isEqual(rhs)
}

public enum PlayerEvent {
    case timeUpdated
    case didPlayToEndTime
    case statusChanged
    case trackSelected(Track, Int, Playlist)
    case trackUnselected(Track, Int, Playlist)
    case previousPlaylistRequested
    case nextPlaylistRequested;
    case errorOccured
    case playlistChanged
    case nextTrackAdded
}

public enum PlayerState {
    case `init`
    case load
    case loadToPlay
    case play
    case pause
    public var isPlaying: Bool {
        return self == PlayerState.loadToPlay || self == PlayerState.play
    }
}

enum CurrentPlayer {
    case normal(NormalPlayer)
    case none
}

open class Player: QueuePlayerObserver, Observable {
    public typealias ObserverType = PlayerObserver
    public typealias EventType    = PlayerEvent
    fileprivate var _observers: [ObserverType] = []
    open  var  observers: [ObserverType] {
        get { return _observers }
        set { _observers = newValue }
    }
    open fileprivate(set) var playlistQueue: PlaylistQueue {
        didSet {
            oldValue.player      = nil
            playlistQueue.player = self
        }
    }
    fileprivate var normalPlayer:     NormalPlayer
//    fileprivate var appleMusicPlayer: AppleMusicPlayer
//    fileprivate var spotifyPlayer:    Spotifylayer

    fileprivate var playlistIndex: Int?
    fileprivate var trackIndex:    Int?

//    fileprivate var timeObserver:  AnyObject?
    public private(set) var state: PlayerState {
        didSet { notify(.statusChanged) }
    }

    open var avPlayer: AVPlayer?  { return normalPlayer.queuePlayer }

    open var playingInfo: PlayingInfo? {
        return nil
    }
    open var currentPlaylist: Playlist?  {
        guard let i = playlistIndex else { return nil }
        return playlistQueue.playlists.get(i)
    }
    open var currentTrackIndex: Int? {
        if currentPlaylist == nil { return nil }
        return trackIndex
    }
    open var currentTrack: Track? {
        if let i = currentTrackIndex, let c = currentPlaylist?.tracks.count {
            if i < c {
                return currentPlaylist?.tracks[i]
            }
        }
        return nil
    }

    open func isSelected(_ trackIndex: Int, playlistIndex: Int) -> Bool {
        if let playlist = currentPlaylist, let index = currentTrackIndex, playlistIndex < playlistQueue.playlists.count {
            return  playlist.id == playlistQueue.playlists[playlistIndex].id && index == trackIndex
        }
        return false
    }


    public override init() {
        state         = .init
        playlistQueue = PlaylistQueue(playlists: [])
        normalPlayer  = NormalPlayer()
        super.init()
        normalPlayer.addObserver(self)
    }

    deinit {
    }

    open override func listen(_ event: QueuePlayerObserver.Event) {
        switch event {
        case .timeUpdated:
            notify(.timeUpdated)
        case .didPlayToEndTime:
            notify(.didPlayToEndTime)
        case .statusChanged:
            notify(.statusChanged)
        case .trackSelected(let track, let index):
            notify(.trackSelected(track, index, currentPlaylist!))
        case .trackUnselected(let track, let index):
            notify(.trackUnselected(track, index, currentPlaylist!))
        case .previousRequested:
            if let indexPath = previousTrackIndexPath() {
                prepare(indexPath[1], playlistIndex: indexPath[0])
            } else {
                notify(.previousPlaylistRequested)
            }
            notify(.previousPlaylistRequested)
        case .nextRequested:
            if let indexPath = nextTrackIndexPath() {
                prepare(indexPath[1], playlistIndex: indexPath[0])
            } else {
                notify(.nextPlaylistRequested)
            }
        case .errorOccured:
            notify(.errorOccured)
        case .nextTrackAdded:
            notify(.nextTrackAdded)
        }
    }

    func prepare(_ trackIndex: Int, playlistIndex: Int) {
        self.playlistIndex = playlistIndex
        self.trackIndex    = trackIndex
        guard let playerType = currentTrack?.playerType else { return }
//        if let p = currentPlaylist {
//            if let i = currentTrackIndex, let t = currentTrack {
//                notify(.trackUnselected(t, i, p))
//            }
//        }

        let playlist = playlistQueue.playlists[playlistIndex]
        let tracks = playlist.createTrackListFrom(trackIndex)

        switch playerType {
        case .normal:
            normalPlayer.prepare(0, of: tracks)
        case .appleMusic:
            break
        case .spotify:
            break
        }
    }

    open func select(_ trackIndex: Int, playlist: Playlist, playlistQueue: PlaylistQueue) -> Bool {
        if let index = playlistQueue.indexOf(playlist) {
            return select(trackIndex: trackIndex, playlistIndex: index, playlistQueue: playlistQueue)
        }
        return false
    }

    fileprivate func select(trackIndex: Int, playlistIndex: Int, playlistQueue: PlaylistQueue) -> Bool {
        if self.playlistQueue == playlistQueue && isSelected(trackIndex, playlistIndex: playlistIndex) {
            return true
        }
        if !(playlistQueue.playlists.get(playlistIndex)?.tracks[trackIndex].isValid ?? true) {
            return false
        }
        self.playlistQueue = playlistQueue
        prepare(trackIndex, playlistIndex: playlistIndex)
        return true
    }

    open func toggle(_ trackIndex: Int, playlist: Playlist, playlistQueue: PlaylistQueue) {
        if let index = playlistQueue.indexOf(playlist) {
            toggle(trackIndex: trackIndex, playlistIndex: index, playlistQueue: playlistQueue)
        }
    }

    fileprivate func toggle(trackIndex: Int, playlistIndex: Int, playlistQueue: PlaylistQueue) {
        if self.playlistQueue == playlistQueue && isSelected(trackIndex, playlistIndex: playlistIndex) {
            toggle()
        } else {
            play(trackIndex: trackIndex, playlistIndex: playlistIndex, playlistQueue: playlistQueue)
        }
    }

    open func play(trackIndex: Int, playlist: Playlist, playlistQueue: PlaylistQueue) {
        if let index = playlistQueue.indexOf(playlist) {
            play(trackIndex: trackIndex, playlistIndex: index, playlistQueue: playlistQueue)
        }
    }

    fileprivate func play(trackIndex: Int, playlistIndex: Int) {
        play(trackIndex: trackIndex, playlistIndex: playlistIndex, playlistQueue: playlistQueue)
    }

    fileprivate func play(trackIndex: Int, playlistIndex: Int, playlistQueue: PlaylistQueue) {
        if self.playlistQueue != playlistQueue || !isSelected(trackIndex, playlistIndex: playlistIndex) {
            self.playlistQueue = playlistQueue
            prepare(trackIndex, playlistIndex: playlistIndex)
        }
        play()
    }

    open func play() {
        guard let playerType = currentTrack?.playerType else { return }
        switch playerType {
        case .normal:
            normalPlayer.play()
        case .appleMusic:
            break
        case .spotify:
            break
        }
    }

    open func pause() {
        guard let playerType = currentTrack?.playerType else { return }
        switch playerType {
        case .normal:
            normalPlayer.pause()
        case .appleMusic:
            break
        case .spotify:
            break
        }
    }

    open func toggle() {
        guard let playerType = currentTrack?.playerType else { return }
        switch playerType {
        case .normal:
            normalPlayer.toggle()
        case .appleMusic:
            break
        case .spotify:
            break
        }
    }

    open var previousTrack: Track? {
        guard let indexPath = previousTrackIndexPath() else { return nil }
        return playlistQueue.playlists[indexPath[0]].tracks[indexPath[1]]
    }

    open var nextTrack: Track? {
        guard let indexPath = nextTrackIndexPath() else { return nil }
        return self.playlistQueue.playlists[indexPath[0]].tracks[indexPath[1]]
    }

    fileprivate func previousTrackIndexPath() -> IndexPath? {
        guard let playlistIndex = playlistIndex else { return nil }
        guard let trackIndex    = trackIndex else { return nil }
        if trackIndex - 1 >= 0 {
            return IndexPath(indexes: [playlistIndex, trackIndex - 1])
        }
        for i in (0..<playlistIndex).reversed() {
            if let playlist = playlistQueue.playlists.get(i), playlist.validTracksCount > 0 {
                return IndexPath(indexes: [i, 0])
            }
        }
        return nil
    }

    fileprivate func nextTrackIndexPath() -> IndexPath? {
        guard let playlistIndex = playlistIndex else { return nil }
        guard let trackIndex    = trackIndex else { return nil }
        guard let playlist = currentPlaylist else { return nil }
        if trackIndex + 1 < playlist.tracks.count {
            return IndexPath(indexes: [playlistIndex, trackIndex])
        }
        for i in playlistIndex+1..<playlistQueue.playlists.count {
            if let playlist = playlistQueue.playlists.get(i), playlist.validTracksCount > 0 {
                return IndexPath(indexes: [i, 0])
            }
        }
        return nil
    }

    open func previous() {
        guard let playerType = currentTrack?.playerType else { return }
        switch playerType {
        case .normal:     return normalPlayer.previous()
        case .appleMusic: break
        case .spotify:    break
        }
    }

    open func next() {
        guard let playerType = currentTrack?.playerType else { return }
        switch playerType {
        case .normal:     return normalPlayer.next()
        case .appleMusic: break
        case .spotify:    break
        }
    }

    func updateTime(_ time: CMTime) {
        notify(.timeUpdated)
    }

    open func seekToTime(_ time: TimeInterval) {
        guard let playerType = currentTrack?.playerType else { return }
        switch playerType {
        case .normal:     return normalPlayer.seekToTime(time)
        case .appleMusic: break
        case .spotify:    break
        }
        notify(.timeUpdated)
    }

    open func nextTrackAdded() {
        notify(.nextTrackAdded)
    }
}
