//  Player.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 3/1/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import AVFoundation

public protocol Track {
    var title:        String? { get }
    var streamUrl:    NSURL?  { get }
    var thumbnailUrl: NSURL?  { get }
    var isVideo:      Bool    { get }
}

public protocol Playlist {
    var id:               String { get }
    var tracks:           [Track] { get }
    var validTracksCount: Int { get }
}

let AVQueuePlayerDidChangeStatusNotification: String = "AVQueuePlayerDidChangeStatus"

class AVQueuePlayerNotificationProxy: NSObject {
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let player = object as? AVQueuePlayer {
            let notificationCenter = NSNotificationCenter.defaultCenter()
            if keyPath  == "status" {
                notificationCenter.postNotificationName(AVQueuePlayerDidChangeStatusNotification, object: player)
            }
        }
    }
}

class ObserverProxy {
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
    func start() { center.addObserver(self, selector:#selector(ObserverProxy.handler(_:)), name:name, object: object) }
    func stop()  { center.removeObserver(self) }
    @objc func handler(notification: NSNotification) { closure(notification); }
}

public class PlayerObserver: NSObject, Observer {
    public typealias Event = PlayerEvent
    public func listen(event: Event) {
    }
}

public func ==(lhs: PlayerObserver, rhs: PlayerObserver) -> Bool {
    return lhs.isEqual(rhs)
}

public enum PlayerEvent {
    case TimeUpdated
    case DidPlayToEndTime
    case StatusChanged
    case TrackSelected(Track, Int, Playlist)
    case TrackUnselected(Track, Int, Playlist)
    case PreviousPlaylistRequested
    case NextPlaylistRequested;
    case ErrorOccured
    case PlaylistChanged
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

public class Player: Observable {
    public typealias ObserverType = PlayerObserver
    public typealias EventType    = PlayerEvent
    private var _observers: [ObserverType] = []
    public  var  observers: [ObserverType] {
        get { return _observers }
        set { _observers = newValue }
    }
    public private(set) var playlists: [Playlist] = []
    private var queuePlayer:   AVQueuePlayer?
    private var playlistIndex: Int?
    private var itemIndex:     Int = -1
    private var currentTime:   CMTime? { get { return queuePlayer?.currentTime() }}
    private var itemCount:     Int = 0
    private var timeObserver:  AnyObject?
    private var state:         PlayerState {
        didSet { notify(.StatusChanged) }
    }
    private var proxy:        AVQueuePlayerNotificationProxy
    private var statusProxy:  ObserverProxy?
    private var endProxy:     ObserverProxy?
    public init() {
        state = .Init
        proxy = AVQueuePlayerNotificationProxy()
        statusProxy = ObserverProxy(name: AVQueuePlayerDidChangeStatusNotification, closure: self.playerDidChangeStatus);
        endProxy    = ObserverProxy(name: AVPlayerItemDidPlayToEndTimeNotification, closure: self.playerDidPlayToEndTime);
    }

    deinit {
        statusProxy?.stop()
        endProxy?.stop()
        statusProxy = nil
        endProxy    = nil
    }

    public var avPlayer:          AVPlayer?  { return queuePlayer }
    public var playerItemsCount:  Int?       { return queuePlayer?.items().count }

    public var currentPlaylist: Playlist?  {
        if let i = playlistIndex {
            if i < playlists.count {
                return playlists[i]
            }
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
        if currentPlaylist == nil { return nil }
        var _indexes: [Int:Int] = [:]
        var c = 0
        for i in 0..<currentPlaylist!.tracks.count {
            if let _ = currentPlaylist!.tracks[i].streamUrl {
                _indexes[c] = i
                c += 1
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
            notify(.TrackUnselected(currentTrack!, i, p))
        }
        self.playlistIndex = playlistIndex
        let playlist = playlists[playlistIndex]
        if let player = self.queuePlayer {
            player.pause()
            if let observer = timeObserver {
                player.removeTimeObserver(observer)
            }
            player.removeAllItems()
            player.removeObserver(self.proxy, forKeyPath: "status")
        }

        var _playerItems: [AVPlayerItem] = []
        itemCount = 0
        itemIndex = 0
        for i in 0..<playlist.tracks.count {
            if let url = playlist.tracks[i].streamUrl {
                itemCount += 1
                if i >= trackIndex {
                    _playerItems.append(AVPlayerItem(URL:url))
                } else {
                    itemIndex += 1
                }
            }
        }

        if itemIndex >= itemCount {
            itemIndex = itemCount - 1
        }
        let player = AVQueuePlayer(items: _playerItems)
        self.queuePlayer = player
        player.seekToTime(kCMTimeZero)
        let time = CMTimeMakeWithSeconds(1.0, 1)
        self.timeObserver = player.addPeriodicTimeObserverForInterval(time, queue:nil, usingBlock:self.updateTime)
        player.addObserver(self.proxy, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
        if let i = currentTrackIndex, track = currentTrack {
            notify(.TrackSelected(track, i, currentPlaylist!))
        }
    }

    public func isCurrentPlaying(trackIndex: Int, playlistIndex: Int, playlists: [Playlist]) -> Bool {
        if let _playlist = currentPlaylist, _index = currentTrackIndex {
            return  _playlist.id == playlists[playlistIndex].id && _index == trackIndex
        }
        return false
    }

    private func getPlaylistIndex(playlist: Playlist, playlists: [Playlist]) -> Int? {
        for i in 0..<playlists.count {
            if playlist.id == playlists[i].id {
                return i
            }
        }
        return nil
    }

    public func select(trackIndex: Int, playlist: Playlist, playlists: [Playlist]) {
        if let index = getPlaylistIndex(playlist, playlists: playlists) {
            select(trackIndex: trackIndex, playlistIndex: index, playlists: playlists)
        }
    }

    public func select(trackIndex trackIndex: Int, playlistIndex: Int, playlists: [Playlist]) {
        if isCurrentPlaying(trackIndex, playlistIndex: playlistIndex, playlists: playlists) {
            toggle()
        } else {
            play(trackIndex: trackIndex, playlistIndex: playlistIndex, playlists: playlists)
        }
    }

    public func play(trackIndex: Int, playlist: Playlist, playlists: [Playlist]) {
        if let index = getPlaylistIndex(playlist, playlists: playlists) {
            play(trackIndex: trackIndex, playlistIndex: index, playlists: playlists)
        }
    }

    public func play(trackIndex trackIndex: Int, playlistIndex: Int) {
        play(trackIndex: trackIndex, playlistIndex: playlistIndex, playlists: playlists)
    }

    public func play(trackIndex trackIndex: Int, playlistIndex: Int, playlists: [Playlist]) {
        if !isCurrentPlaying(trackIndex, playlistIndex: playlistIndex, playlists: playlists) {
            self.playlists = playlists
            prepare(trackIndex, playlistIndex: playlistIndex)
        }
        if let player = self.queuePlayer {
            if player.items().count == 0 {
                notify(.NextPlaylistRequested)
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

    public func play() {
        if let _playlistIndex = playlistIndex {
            play(trackIndex: itemIndex, playlistIndex: _playlistIndex, playlists: playlists)
        }
    }

    public func pause() {
        queuePlayer?.pause()
        state = .Pause
    }

    public func toggle() {
        if itemIndex == -1 || queuePlayer == nil || currentPlaylist == nil {
            return
        }
        if state.isPlaying {
            queuePlayer?.pause()
            state = .Pause
        } else {
            play()
        }
    }

    public var previousTrack: Track? {
        guard let (trackIndex, playlistIndex) = previousTrackIndexes() else {
            return nil
        }
        return self.playlists[playlistIndex].tracks[trackIndex]
    }
    
    private func previousTrackIndexes() -> (Int, Int)? {
        if let i = trackIndex(itemIndex-1) {
            return (i, playlistIndex!)
        } else if playlistIndex > 0 {
            let i = playlistIndex! - 1
            return (playlists[i].validTracksCount - 1, i)
        } else {
            return nil
        }
    }

    public func previous() {
        guard let (trackIndex, playlistIndex) = previousTrackIndexes() else {
            notify(.PreviousPlaylistRequested)
            return
        }
        if state.isPlaying {
            play(trackIndex: trackIndex, playlistIndex: playlistIndex)
        } else {
            prepare(trackIndex, playlistIndex: playlistIndex)
            state = .Pause
        }
    }
    
    public var nextTrack: Track? {
        guard let (trackIndex, playlistIndex) = nextTrackIndexes() else {
            return nil
        }
        return self.playlists[playlistIndex].tracks[trackIndex]
    }

    private func nextTrackIndexes() -> (Int, Int)? {
        if let i = trackIndex(itemIndex+1) {
            return (i, playlistIndex!)
        } else if playlistIndex != nil && playlistIndex! + 1 < playlists.count {
            return (0, playlistIndex! + 1)
        } else {
            return nil
        }
    }

    public func next() {
        guard let (trackIndex, playlistIndex) = nextTrackIndexes() else {
            notify(.NextPlaylistRequested)
            return
        }
        if state.isPlaying {
            play(trackIndex: trackIndex, playlistIndex: playlistIndex)
        } else {
            prepare(trackIndex, playlistIndex: playlistIndex)
            state = .Pause
        }
    }

    func playerDidPlayToEndTime(notification: NSNotification) {
        if currentPlaylist == nil {
            return
        }
        if let qp = queuePlayer, item = qp.currentItem {
            qp.removeItem(item)
        }
        notify(.TrackUnselected(currentTrack!, currentTrackIndex!, currentPlaylist!))
        itemIndex = (itemIndex + 1) % itemCount
        if itemIndex == 0 {
            if playlistIndex! + 1 < playlists.count {
                play(trackIndex: 0, playlistIndex: playlistIndex! + 1)
            } else {
                notify(.NextPlaylistRequested)
            }
        } else {
            notify(.TrackSelected(currentTrack!, currentTrackIndex!, currentPlaylist!))
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
                notify(.ErrorOccured)
            case .Unknown:
                notify(.ErrorOccured)
            }
        }
    }

    func updateTime(time: CMTime) {
        if let _ = queuePlayer {
            notify(.TimeUpdated)
        }
    }

    public func seekToTime(time: CMTime) {
        queuePlayer?.seekToTime(time)
    }
}
