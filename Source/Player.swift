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
    fileprivate var queuePlayers: [QueuePlayer]

    fileprivate var normalPlayer: NormalPlayer? {
        for player in queuePlayers {
            if let player = player as? NormalPlayer {
                return player
            }
        }
        return nil
    }

    fileprivate var appleMusicPlayer: AppleMusicPlayer? {
        for player in queuePlayers {
            if let player = player as? AppleMusicPlayer {
                return player
            }
        }
        return nil
    }
    
    fileprivate var spotifyPlayer: SpotifyPlayer? {
        for player in queuePlayers {
            if let player = player as? SpotifyPlayer {
                return player
            }
        }
        return nil
    }


    fileprivate var playlistIndex: Int?
    fileprivate var trackIndex:    Int?

    public var state: PlayerState {
        if let type = currentTrack?.playerType {
            switch type {
            case .normal:     return normalPlayer?.state     ?? .init
            case .appleMusic: return appleMusicPlayer?.state ?? .init
            case .spotify:    return spotifyPlayer?.state    ?? .init
            }
        }
        return .init
    }

    open var avPlayer: AVPlayer?  {
        if let type = currentTrack?.playerType {
            switch type {
            case .normal:
                return normalPlayer?.queuePlayer
            default:
                return nil
            }
        }
        return nil
    }
    open var playingInfo: PlayingInfo? {
        if let type = currentTrack?.playerType {
            switch type {
            case .normal:     return normalPlayer?.playingInfo
            case .appleMusic: return appleMusicPlayer?.playingInfo
            case .spotify:    return spotifyPlayer?.playingInfo
            }
        }
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
        playlistQueue    = PlaylistQueue(playlists: [])
        queuePlayers     = []
        super.init()
        addPlayer(NormalPlayer())
        addPlayer(AppleMusicPlayer())
    }

    deinit {
    }

    open func addPlayer(_ player: QueuePlayer) {
        if var player = player as? NormalPlayer {
            player.addObserver(self)
        }
        if var player = player as? AppleMusicPlayer {
            player.addObserver(self)
        }
        if var player = player as? SpotifyPlayer {
            player.addObserver(self)
        }
        queuePlayers.append(player)
    }

    open override func listen(_ event: QueuePlayerObserver.Event) {
        switch event {
        case .timeUpdated:
            notify(.timeUpdated)
        case .didPlayToEndTime:
            notify(.didPlayToEndTime)
        case .statusChanged:
            notify(.statusChanged)
        case .trackSelected(let track, _):
            notify(.trackSelected(track, currentTrackIndex!, currentPlaylist!))
        case .trackUnselected(let track, _):
            notify(.trackUnselected(track, currentTrackIndex!, currentPlaylist!))
        case .previousRequested:
            if let _ = previousTrackIndexPath() {
                previous()
                play()
            } else {
                notify(.previousPlaylistRequested)
            }
        case .nextRequested:
            if let _ = nextTrackIndexPath() {
                next()
                play()
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
        let tracks = playlist.createTrackList(with: trackIndex)
        normalPlayer?.clearPlayer()
        appleMusicPlayer?.clearPlayer()
        spotifyPlayer?.clearPlayer()
        switch playerType {
        case .normal:     normalPlayer?.prepare(    0, of: tracks)
        case .appleMusic: appleMusicPlayer?.prepare(0, of: tracks)
        case .spotify:    spotifyPlayer?.prepare(   0, of: tracks)
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
        case .normal:     normalPlayer?.play()
        case .appleMusic: appleMusicPlayer?.play()
        case .spotify:    spotifyPlayer?.play()
        }
    }

    open func pause() {
        guard let playerType = currentTrack?.playerType else { return }
        switch playerType {
        case .normal:     normalPlayer?.pause()
        case .appleMusic: appleMusicPlayer?.pause()
        case .spotify:    spotifyPlayer?.pause()
        }
    }

    open func toggle() {
        guard let playerType = currentTrack?.playerType else { return }
        switch playerType {
        case .normal:     normalPlayer?.toggle()
        case .appleMusic: appleMusicPlayer?.toggle()
        case .spotify:    spotifyPlayer?.toggle()
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
        guard var playlistIndex = playlistIndex else { return nil }
        guard var trackIndex    = trackIndex    else { return nil }
        guard var playlist      = currentPlaylist else { return nil }
        while (true) {
            trackIndex -= 1
            if trackIndex >= 0 {
                let track = playlist.tracks[trackIndex]
                if track.isValid {
                    return IndexPath(indexes: [playlistIndex, trackIndex])
                }
            } else {
                playlistIndex -= 1
                if playlistIndex < 0 {
                    return nil
                } else {
                    playlist   = playlistQueue.playlists[playlistIndex]
                    trackIndex = playlist.tracks.count
                }
            }
        }
    }

    fileprivate func nextTrackIndexPath() -> IndexPath? {
        guard var playlistIndex = playlistIndex else { return nil }
        guard var trackIndex    = trackIndex else { return nil }
        guard var playlist = currentPlaylist else { return nil }
        while (true) {
            trackIndex += 1
            if trackIndex < playlist.tracks.count {
                let track = playlist.tracks[trackIndex]
                if track.isValid {
                    return IndexPath(indexes: [playlistIndex, trackIndex])
                }
            } else {
                playlistIndex += 1
                trackIndex     = -1
                if playlistIndex >= playlistQueue.playlists.count {
                    return nil
                } else {
                    playlist = playlistQueue.playlists[playlistIndex]
                }
            }
        }
    }

    open func previous() {
        guard let _ = currentTrack?.playerType else { return }
        guard let indexPath = previousTrackIndexPath() else { return }
        let isPlaying = state.isPlaying
        prepare(indexPath[1], playlistIndex: indexPath[0])
        if isPlaying {
            play()
        } else {
            pause()
        }
    }

    open func next() {
        guard let _ = currentTrack?.playerType else { return }
        guard let indexPath = nextTrackIndexPath() else { return }
        let isPlaying = state.isPlaying
        prepare(indexPath[1], playlistIndex: indexPath[0])
        if isPlaying {
            play()
        } else {
            pause()
        }
    }

    func updateTime(_ time: CMTime) {
        notify(.timeUpdated)
    }

    open func seekToTime(_ time: TimeInterval) {
        guard let playerType = currentTrack?.playerType else { return }
        switch playerType {
        case .normal:     normalPlayer?.seekToTime(time)
        case .appleMusic: appleMusicPlayer?.seekToTime(time)
        case .spotify:    spotifyPlayer?.seekToTime(time)
        }
        notify(.timeUpdated)
    }

    open func nextTrackAdded() {
        notify(.nextTrackAdded)
    }
}
