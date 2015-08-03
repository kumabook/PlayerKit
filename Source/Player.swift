//  Player.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 3/1/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import AVFoundation

public class Track {
    public var streamUrl: NSURL?
}

public class Playlist: Equatable, Hashable {
    public var id:           String = ""
    public var title:        String = ""
    public var tracks:       [Track] = []

    public var validTracksCount: Int { return tracks.count }

    public var hashValue: Int {
        return id.hashValue
    }
}

public func ==(lhs: Playlist, rhs: Playlist) -> Bool {
    return lhs.id == rhs.id
}

public class Observable<T: PlayerObserver>: NSObject {
    var observers: [PlayerObserver] = []
    override init() {
        super.init()
    }
    public func addObserver(observer: T) {
        observers.append(observer)
    }
    public func removeObserver(observer: T) {
        if let index = find(observers, observer) {
            observers.removeAtIndex(index)
        }
    }
}

let AVQueuePlayerDidChangeStatusNotification: String = "AVQueuePlayerDidChangeStatus"

class AVQueuePlayerNotificationProxy: NSObject {
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if let player = object as? AVQueuePlayer {
            let notificationCenter = NSNotificationCenter.defaultCenter()
            if keyPath  == "status" {
                notificationCenter.postNotificationName(AVQueuePlayerDidChangeStatusNotification, object: player)
            }
        }
    }
}

@objc class ObserverProxy {
    var closure: (NSNotification) -> ();
    var name: String;
    var object: AnyObject?;
    var center: NSNotificationCenter { get { return NSNotificationCenter.defaultCenter() } }
    init(name: String, closure: (NSNotification) -> ()) {
        self.closure = closure;
        self.name = name;
        self.start();
    }
    convenience init(name: String, object: AnyObject, closure: (NSNotification) -> ()) {
        self.init(name: name, closure: closure);
        self.object = object;
    }
    deinit { stop() }
    func start() { center.addObserver(self, selector:"handler:", name:name, object: object); }
    func stop()  { center.removeObserver(self); }
    func handler(notification: NSNotification) { closure(notification); }
}

public class PlayerObserver: NSObject, Equatable {
    public func timeUpdated() {}
    public func didPlayToEndTime() {}
    public func statusChanged() {}
    public func trackSelected(track: Track, index: Int, playlist: Playlist) {}
    public func trackUnselected(track: Track, index: Int, playlist: Playlist) {}
    public func previousPlaylistRequested() {}
    public func nextPlaylistRequested() {}
    public func errorOccured() {}
}

public func ==(lhs: PlayerObserver, rhs: PlayerObserver) -> Bool {
    return lhs.isEqual(rhs)
}

public enum PlayerState {
    case Init
    case Load
    case LoadToPlay
    case Play
    case Pause
    public var isPlaying: Bool {
        return self == LoadToPlay || self == Play
    }
}

@objc public class Player<T: PlayerObserver>: Observable<T> {
    private var queuePlayer:   AVQueuePlayer?
    private var playlists:     [Playlist] = []
    private var playlistIndex: Int?
    private var itemIndex:     Int = -1
    private var currentTime:   CMTime? { get { return queuePlayer?.currentTime() }}
    private var itemCount:        Int = 0
    private var timeObserver:  AnyObject?
    private var state:         PlayerState {
        didSet { statusChanged() }
    }
    private var proxy:        AVQueuePlayerNotificationProxy
    private var statusProxy:  ObserverProxy?;
    private var endProxy:     ObserverProxy?;
    public override init() {
        state = .Init
        proxy = AVQueuePlayerNotificationProxy()
        super.init()
        statusProxy = ObserverProxy(name: AVQueuePlayerDidChangeStatusNotification, closure: self.playerDidChangeStatus);
        endProxy    = ObserverProxy(name: AVPlayerItemDidPlayToEndTimeNotification, closure: self.playerDidPlayToEndTime);
    }

    deinit {
        statusProxy?.stop()
        endProxy?.stop()
        statusProxy = nil
        endProxy    = nil
    }

    func timeUpdated() {
        for o in observers { o.timeUpdated() }
    }
    func didPlayToEndTime()        { for o in observers { o.didPlayToEndTime() }}
    func statusChanged()           { for o in observers { o.statusChanged() }}
    func trackSelected(track: Track, index: Int, playlist: Playlist) {
        for o in observers {
            o.trackSelected(track, index: index, playlist: playlist)
        }
    }
    func trackUnselected(track: Track, index: Int, playlist: Playlist) {
        for o in observers {
            o.trackUnselected(track, index: index, playlist: playlist)
        }
    }
    func previousPlaylistRequested() { for o in observers { o.previousPlaylistRequested() }}
    func nextPlaylistRequested()     { for o in observers { o.nextPlaylistRequested() }}
    func errorOccured()              { for o in observers { o.errorOccured() }}

    public var avPlayer:          AVPlayer?  { return queuePlayer }
    public var playerItemsCount:  Int?       { return queuePlayer?.items().count }

    public var currentPlaylist: Playlist?  {
        if let i = playlistIndex {
            return playlists[i]
        }
        return nil
    }
    public var currentTrackIndex: Int? {
        if currentPlaylist == nil { return nil }
        return trackIndex(itemIndex)
    }
    public var currentState:     PlayerState { return state }
    public var currentTrack:     Track? {
        if let i = currentTrackIndex, c = currentPlaylist?.tracks.count {
            if i < c {
                return currentPlaylist?.tracks[i]
            }
        }
        return nil
    }
    public var secondPair:       (Float64, Float64)? {
        get {
            if let count = playerItemsCount {
                if count == 0 { return nil }
                if let item = queuePlayer?.currentItem {
                    return (CMTimeGetSeconds(item.currentTime()), CMTimeGetSeconds(item.duration))
                }
            }
            return nil
        }
    }

    public func trackIndex(itemIndex: Int) -> Int? {
        var _indexes: [Int:Int] = [:]
        var c = 0
        for i in 0..<currentPlaylist!.tracks.count {
            if let url = currentPlaylist!.tracks[i].streamUrl {
                _indexes[c++] = i
            }
        }
        if 0 <= itemIndex && itemIndex < c {
            return _indexes[itemIndex]!
        } else {
            return nil
        }
    }

    func prepare(trackIndex: Int, playlistIndex: Int) {
        if let p = currentPlaylist, i = currentTrackIndex {
            trackUnselected(currentTrack!, index: i, playlist: p)
        }
        self.playlistIndex = playlistIndex
        let playlist = playlists[playlistIndex]
        if let player = self.queuePlayer {
            player.pause()
            player.removeTimeObserver(self.timeObserver)
            player.removeAllItems()
            player.removeObserver(self.proxy, forKeyPath: "status")
        }

        var _playerItems: [AVPlayerItem] = []
        itemCount = 0
        itemIndex = 0
        for i in 0..<playlist.tracks.count {
            if let url = playlist.tracks[i].streamUrl {
                itemCount++
                if i >= trackIndex {
                    _playerItems.append(AVPlayerItem(URL:url))
                } else {
                    itemIndex++
                }
            }
        }

        if itemIndex >= itemCount {
            itemIndex = itemCount - 1
        }
        let player = AVQueuePlayer(items: _playerItems)
        self.queuePlayer = player
        player.seekToTime(kCMTimeZero)
        var time = CMTimeMakeWithSeconds(1.0, 1)
        self.timeObserver = player.addPeriodicTimeObserverForInterval(time, queue:nil, usingBlock:self.updateTime)
        player.addObserver(self.proxy, forKeyPath: "status", options: NSKeyValueObservingOptions.allZeros, context: nil)
        if let i = currentTrackIndex, track = currentTrack {
            trackSelected(track, index: i, playlist: currentPlaylist!)
        }
    }

    public func isCurrentPlaying(trackIndex: Int, playlistIndex: Int, playlists: [Playlist]) -> Bool {
        if let _playlist = currentPlaylist, _index = currentTrackIndex {
            return  _playlist.id == playlists[playlistIndex].id && _index == trackIndex
        }
        return false
    }

    public func select(#trackIndex: Int, playlistIndex: Int, playlists: [Playlist]) {
        if isCurrentPlaying(trackIndex, playlistIndex: playlistIndex, playlists: playlists) {
            toggle()
        } else {
            play(trackIndex: trackIndex, playlistIndex: playlistIndex, playlists: playlists)
        }
    }

    public func play(#trackIndex: Int, playlistIndex: Int) {
        play(trackIndex: trackIndex, playlistIndex: playlistIndex, playlists: playlists)
    }

    public func play(#trackIndex: Int, playlistIndex: Int, playlists: [Playlist]) {
        if !isCurrentPlaying(trackIndex, playlistIndex: playlistIndex, playlists: playlists) {
            self.playlists = playlists
            prepare(trackIndex, playlistIndex: playlistIndex)
        }
        if let player = self.queuePlayer {
            if player.items().count == 0 {
                nextPlaylistRequested()
            } else {
                player.play()
                if player.status == AVPlayerStatus.ReadyToPlay { state = .Play }
                else                                           { state = .LoadToPlay }
            }
        }
    }

    public func keepPlaying() {
        if state.isPlaying {
            queuePlayer?.pause()
            queuePlayer?.play()
        }
    }

    public func toggle() {
        if itemIndex == -1 || queuePlayer == nil || currentPlaylist == nil {
            return
        }
        if state.isPlaying {
            queuePlayer!.pause()
            state = .Pause
        } else {
            play(trackIndex: itemIndex, playlistIndex: playlistIndex!, playlists: playlists)
        }
    }

    public func previous() {
        var previousTrackIndex: Int
        var previousPlaylistIndex: Int
        if let i = trackIndex(itemIndex-1) {
            previousTrackIndex    = i
            previousPlaylistIndex = playlistIndex!
        } else if playlistIndex > 0 {
            previousPlaylistIndex = playlistIndex! - 1
            previousTrackIndex    = playlists[previousPlaylistIndex].validTracksCount - 1
        } else {
            previousPlaylistRequested()
            return
        }
        if state.isPlaying {
            play(trackIndex: previousTrackIndex, playlistIndex: previousPlaylistIndex)
        } else {
            prepare(previousTrackIndex, playlistIndex: previousPlaylistIndex)
            state = .Pause
        }

    }

    public func next() {
        var nextTrackIndex: Int
        var nextPlaylistIndex: Int
        if let i = trackIndex(itemIndex+1) {
            nextTrackIndex    = i
            nextPlaylistIndex = playlistIndex!
        } else if playlistIndex! + 1 < playlists.count {
            nextTrackIndex    = 0
            nextPlaylistIndex =  playlistIndex! + 1
        } else {
            nextPlaylistRequested()
            return
        }
        if state.isPlaying {
            play(trackIndex: nextTrackIndex, playlistIndex: nextPlaylistIndex)
        } else {
            prepare(nextTrackIndex, playlistIndex: nextPlaylistIndex)
            state = .Pause
        }
    }

    func playerDidPlayToEndTime(notification: NSNotification) {
        if currentPlaylist == nil {
            return
        }
        queuePlayer!.removeItem(queuePlayer!.currentItem)
        trackUnselected(currentTrack!, index: currentTrackIndex!, playlist: currentPlaylist!)
        itemIndex = (itemIndex + 1) % itemCount
        if itemIndex == 0 {
            if playlistIndex! + 1 < playlists.count {
                play(trackIndex: 0, playlistIndex: playlistIndex! + 1)
            } else {
                nextPlaylistRequested()
            }
        } else {
            trackSelected(currentTrack!, index: currentTrackIndex!, playlist: currentPlaylist!)
        }
    }

    func playerDidChangeStatus(notification: NSNotification) {
        if currentPlaylist == nil {
            return
        }
        if let player = queuePlayer {
            switch player.status {
            case .ReadyToPlay:
                switch state {
                case .Load:
                    state = .Pause
                case .LoadToPlay:
                    state = .Play
                default:
                    break
                }
            case .Failed:
                errorOccured()
            case .Unknown:
                errorOccured()
            }
        }
    }

    func updateTime(time: CMTime) {
        if let player = queuePlayer {
            timeUpdated()
        }
    }

    public func seekToTime(time: CMTime) {
        queuePlayer?.seekToTime(time)
    }
}
