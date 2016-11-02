//  Player.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 3/1/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import AVFoundation


let AVQueuePlayerDidChangeStatusNotification: String = "AVQueuePlayerDidChangeStatus"

class AVQueuePlayerNotificationProxy: NSObject {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let player = object as? AVQueuePlayer {
            let notificationCenter = NotificationCenter.default
            if keyPath  == "status" {
                notificationCenter.post(name: Notification.Name(rawValue: AVQueuePlayerDidChangeStatusNotification), object: player)
            }
        }
    }
}

class ObserverProxy {
    var closure: (Notification) -> ();
    var name: String;
    var object: AnyObject?;
    var center: NotificationCenter { get { return NotificationCenter.default } }
    init(name: String, closure: @escaping (Notification) -> ()) {
        self.closure = closure;
        self.name = name;
        self.start();
    }
    convenience init(name: String, object: AnyObject, closure: @escaping (Notification) -> ()) {
        self.init(name: name, closure: closure);
        self.object = object;
    }
    deinit { stop() }
    func start() { center.addObserver(self, selector:#selector(ObserverProxy.handler(_:)), name:NSNotification.Name(rawValue: name), object: object) }
    func stop()  { center.removeObserver(self) }
    @objc func handler(_ notification: Notification) { closure(notification); }
}

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

open class Player: Observable {
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
    fileprivate var queuePlayer:   AVQueuePlayer?
    fileprivate var currentTime:   CMTime? { get { return queuePlayer?.currentTime() }}
    fileprivate var itemIndex:     Int = -1
    fileprivate var playlistIndex: Int?

    fileprivate var itemCount:     Int = 0
    fileprivate var timeObserver:  AnyObject?
    fileprivate var state:         PlayerState {
        didSet { notify(.statusChanged) }
    }
    fileprivate var proxy:        AVQueuePlayerNotificationProxy
    fileprivate var statusProxy:  ObserverProxy?
    fileprivate var endProxy:     ObserverProxy?

    fileprivate func getPlaylist(_ index: Int, playlistQueue: PlaylistQueue) -> Playlist? {
        if index < playlistQueue.playlists.count {
            return playlistQueue.playlists[index]
        }
        return nil
    }
    fileprivate func getTrack(_ index: Int, playlist: Playlist) -> Track? {
        if index < playlist.tracks.count {
            return playlist.tracks[index]
        }
        return nil
    }

    open var currentPlaylist: Playlist?  {
        guard let i = playlistIndex else { return nil }
        return getPlaylist(i, playlistQueue: playlistQueue)
    }
    open var currentTrackIndex: Int? {
        if currentPlaylist == nil { return nil }
        return trackIndex(itemIndex)
    }
    open var currentTrack:     Track? {
        if let i = currentTrackIndex, let c = currentPlaylist?.tracks.count {
            if i < c {
                return currentPlaylist?.tracks[i]
            }
        }
        return nil
    }
    open func trackIndex(_ itemIndex: Int) -> Int? {
        guard let currentPlaylist = currentPlaylist else { return nil }
        var _indexes: [Int:Int] = [:]
        var c = 0
        for i in 0..<currentPlaylist.tracks.count {
            if currentPlaylist.tracks[i].isValid {
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

    open func isCurrentPlaying(_ trackIndex: Int, playlistIndex: Int) -> Bool {
        if let _playlist = currentPlaylist, let _index = currentTrackIndex, playlistIndex < playlistQueue.playlists.count {
            return  _playlist.id == playlistQueue.playlists[playlistIndex].id && _index == trackIndex
        }
        return false
    }


    public init() {
        state         = .init
        proxy         = AVQueuePlayerNotificationProxy()
        playlistQueue = PlaylistQueue(playlists: [])
        statusProxy   = ObserverProxy(name: AVQueuePlayerDidChangeStatusNotification, closure: self.playerDidChangeStatus);
        endProxy      = ObserverProxy(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue, closure: self.playerDidPlayToEndTime);
    }

    deinit {
        statusProxy?.stop()
        endProxy?.stop()
        statusProxy = nil
        endProxy    = nil
    }

    open var avPlayer:          AVPlayer?  { return queuePlayer }
    open var playerItemsCount:  Int?       { return queuePlayer?.items().count }

    open var currentState:     PlayerState { return state }
    open var secondPair:       (Float64, Float64)? {
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

    func prepare(_ trackIndex: Int, playlistIndex: Int) {
        if let p = currentPlaylist {
            if let i = currentTrackIndex, let t = currentTrack {
                notify(.trackUnselected(t, i, p))
            }
        }
        self.playlistIndex = playlistIndex
        let playlist = playlistQueue.playlists[playlistIndex]
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
                    _playerItems.append(AVPlayerItem(url:url as URL))
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
        player.seek(to: kCMTimeZero)
        let time = CMTimeMakeWithSeconds(1.0, 1)
        self.timeObserver = player.addPeriodicTimeObserver(forInterval: time, queue:nil, using:self.updateTime) as AnyObject?
        player.addObserver(self.proxy, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
        if let i = currentTrackIndex, let track = currentTrack {
            notify(.trackSelected(track, i, currentPlaylist!))
        }
    }

    open func select(_ trackIndex: Int, playlist: Playlist, playlistQueue: PlaylistQueue) -> Bool {
        if let index = playlistQueue.indexOf(playlist) {
            return select(trackIndex: trackIndex, playlistIndex: index, playlistQueue: playlistQueue)
        }
        return false
    }

    open func select(trackIndex: Int, playlistIndex: Int, playlistQueue: PlaylistQueue) -> Bool {
        if self.playlistQueue == playlistQueue && isCurrentPlaying(trackIndex, playlistIndex: playlistIndex) {
            return true
        }
        if !(getPlaylist(playlistIndex, playlistQueue: playlistQueue)?.tracks[trackIndex].isValid ?? true) {
            return false
        }
        self.playlistQueue = playlistQueue
        prepare(trackIndex, playlistIndex: playlistIndex)
        return true
    }

    open func toggle(_ trackIndex: Int, playlist: Playlist, playlistQueue: PlaylistQueue) -> Bool {
        if let index = playlistQueue.indexOf(playlist) {
            return toggle(trackIndex: trackIndex, playlistIndex: index, playlistQueue: playlistQueue)
        }
        return false
    }

    open func toggle(trackIndex: Int, playlistIndex: Int, playlistQueue: PlaylistQueue) -> Bool {
        if self.playlistQueue == playlistQueue && isCurrentPlaying(trackIndex, playlistIndex: playlistIndex) {
            toggle()
            return true
        } else {
            return play(trackIndex: trackIndex, playlistIndex: playlistIndex, playlistQueue: playlistQueue)
        }
    }

    open func play(trackIndex: Int, playlist: Playlist, playlistQueue: PlaylistQueue) -> Bool {
        if let index = playlistQueue.indexOf(playlist) {
            return play(trackIndex: trackIndex, playlistIndex: index, playlistQueue: playlistQueue)
        }
        return false
    }

    open func play(trackIndex: Int, playlistIndex: Int) -> Bool {
        return play(trackIndex: trackIndex, playlistIndex: playlistIndex, playlistQueue: playlistQueue)
    }

    open func play(trackIndex: Int, playlistIndex: Int, playlistQueue: PlaylistQueue) -> Bool {
        if self.playlistQueue != playlistQueue || !isCurrentPlaying(trackIndex, playlistIndex: playlistIndex) {
            self.playlistQueue = playlistQueue
            prepare(trackIndex, playlistIndex: playlistIndex)
        }
        if let player = self.queuePlayer {
            if player.items().count == 0 {
                notify(.nextPlaylistRequested)
            } else {
                player.play()
                if player.status == AVPlayerStatus.readyToPlay { state = .play }
                else                                           { state = .loadToPlay }
                return true
            }
        }
        return false
    }

    open func keepPlaying() {
        if state.isPlaying {
            queuePlayer?.pause()
            queuePlayer?.play()
        }
    }

    open func play() -> Bool {
        if let _playlistIndex = playlistIndex {
            return play(trackIndex: itemIndex, playlistIndex: _playlistIndex, playlistQueue: playlistQueue)
        }
        return false
    }

    open func pause() {
        queuePlayer?.pause()
        state = .pause
    }

    open func toggle() {
        if itemIndex == -1 || queuePlayer == nil || currentPlaylist == nil {
            return
        }
        if state.isPlaying {
            queuePlayer?.pause()
            state = .pause
        } else {
            let _ = play()
        }
    }

    open var previousTrack: Track? {
        guard let (trackIndex, playlistIndex) = previousTrackIndexes() else {
            return nil
        }
        return self.playlistQueue.playlists[playlistIndex].tracks[trackIndex]
    }
    
    fileprivate func previousTrackIndexes() -> (Int, Int)? {
        guard let playlistIndex = playlistIndex else { return nil }
        if let i = trackIndex(itemIndex-1) {
            return (i, playlistIndex)
        }
        for i in (0..<playlistIndex).reversed() {
            if let playlist = getPlaylist(i, playlistQueue: playlistQueue), playlist.validTracksCount > 0 {
                return (0, i)
            }
        }
        return nil
    }

    open func previous() {
        guard let (trackIndex, playlistIndex) = previousTrackIndexes() else {
            notify(.previousPlaylistRequested)
            return
        }
        if state.isPlaying {
            let _ = play(trackIndex: trackIndex, playlistIndex: playlistIndex)
        } else {
            prepare(trackIndex, playlistIndex: playlistIndex)
            state = .pause
        }
    }
    
    open var nextTrack: Track? {
        guard let (trackIndex, playlistIndex) = nextTrackIndexes() else {
            return nil
        }
        return self.playlistQueue.playlists[playlistIndex].tracks[trackIndex]
    }

    fileprivate func nextTrackIndexes() -> (Int, Int)? {
        guard let playlistIndex = playlistIndex else { return nil }
        guard let _ = currentPlaylist else { return nil }
        if let i = trackIndex(itemIndex+1) {
            return (i, playlistIndex)
        }
        for i in playlistIndex+1..<playlistQueue.playlists.count {
            if let playlist = getPlaylist(i, playlistQueue: playlistQueue), playlist.validTracksCount > 0 {
                return (0, i)
            }
        }
        return nil
    }

    open func next() {
        guard let (trackIndex, playlistIndex) = nextTrackIndexes() else {
            notify(.nextPlaylistRequested)
            return
        }
        if state.isPlaying {
            let _ = play(trackIndex: trackIndex, playlistIndex: playlistIndex)
        } else {
            prepare(trackIndex, playlistIndex: playlistIndex)
            state = .pause
        }
    }

    func playerDidPlayToEndTime(_ notification: Notification) {
        if currentPlaylist == nil {
            return
        }
        if let qp = queuePlayer, let item = qp.currentItem {
            qp.remove(item)
        }
        notify(.trackUnselected(currentTrack!, currentTrackIndex!, currentPlaylist!))
        itemIndex = (itemIndex + 1) % itemCount
        if itemIndex == 0 {
            if playlistIndex! + 1 < playlistQueue.playlists.count {
                let _ = play(trackIndex: 0, playlistIndex: playlistIndex! + 1)
            } else {
                notify(.nextPlaylistRequested)
            }
        } else {
            notify(.trackSelected(currentTrack!, currentTrackIndex!, currentPlaylist!))
        }
    }

    func playerDidChangeStatus(_ notification: Notification) {
        if currentPlaylist == nil {
            return
        }
        if let player = queuePlayer {
            switch player.status {
            case .readyToPlay:
                switch state {
                case .load:
                    state = .pause
                case .loadToPlay:
                    state = .play
                    notify(.timeUpdated)
                default:
                    break
                }
            case .failed:
                notify(.errorOccured)
            case .unknown:
                notify(.errorOccured)
            }
        }
    }

    func updateTime(_ time: CMTime) {
        if let _ = queuePlayer {
            notify(.timeUpdated)
        }
    }

    open func seekToTime(_ time: CMTime) {
        queuePlayer?.seek(to: time)
        notify(.timeUpdated)
    }

    open func nextTrackAdded() {
        notify(.nextTrackAdded)
    }
}
