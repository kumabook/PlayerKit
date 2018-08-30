//
//  AppleMusicPlayer.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/03/09.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation
import MediaPlayer


class AppleMusicPlayer: ServicePlayer {
    typealias ObserverType = ServicePlayerObserver
    typealias EventType    = ServicePlayerEvent
    fileprivate static let delayForPlaybackStateDidChange = 0.01
    fileprivate var _observers: [ObserverType] = []
    open        var  observers: [ObserverType] {
        get { return _observers }
        set { _observers = newValue }
    }
    public fileprivate(set) var musicPlayerController: MPMusicPlayerController

    internal var track: Track?

    fileprivate var timeObserver:        AnyObject?
    fileprivate var playbackStateProxy:  ObserverProxy?
    fileprivate var nowPlayingItemProxy: ObserverProxy?
    fileprivate var timer:        Timer?
    internal fileprivate(set) var state: PlayerState {
        didSet {
            if oldValue != state {
                notify(.statusChanged)
            }
        }
    }

    init() {
        state                = .init
        track                 = nil
        musicPlayerController = MPMusicPlayerController.applicationMusicPlayer
        playbackStateProxy    = ObserverProxy(name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
                                           closure: self.playbackStateDidChange)
        nowPlayingItemProxy   = ObserverProxy(name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
                                           closure: self.nowPlayingItemDidChange)
        musicPlayerController.beginGeneratingPlaybackNotifications()
    }

    fileprivate func syncPlaybackState() {
        switch self.musicPlayerController.playbackState {
        case .playing:     self.state = .play
        case .paused:      self.state = .pause
        case .stopped:     self.state = .pause
        case .interrupted: self.state = .pause
        default:        break
        }
    }
    
    // MARK: Notification handler
    func nowPlayingItemDidChange(_ notification: Notification) {
        if let _ = musicPlayerController.nowPlayingItem {
            return
        }
        switch state {
        case .play: notify(.didPlayToEndTime)
        default:            return
        }
    }
    
    func playbackStateDidChange(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + AppleMusicPlayer.delayForPlaybackStateDidChange) {
            self.syncPlaybackState()
        }
    }
    
    @objc func updateTime() {
        notify(.timeUpdated)
        switch self.musicPlayerController.playbackState {
        case .playing: self.state = .play
        default:       break
        }
    }
    
    // MARK: QueuePlayer protocol
    var playerType:  PlayerType     { return PlayerType.appleMusic }
    var playingInfo: PlayingInfo? {
        if let item = musicPlayerController.nowPlayingItem {
            return PlayingInfo(duration: item.playbackDuration,
                            elapsedTime: musicPlayerController.currentPlaybackTime)
        }
        return nil
    }

    func seekToTime(_ time: TimeInterval) {
        musicPlayerController.currentPlaybackTime = time
        notify(.timeUpdated)
    }
    
    open func keepPlaying() {
        if state.isPlaying {
            musicPlayerController.pause()
            musicPlayerController.play()
        }
    }
    
    func play() {
        state = .loadToPlay
        if musicPlayerController.isPreparedToPlay {
            musicPlayerController.play()
            return
        }
        if #available(iOS 10.1, *) {
            musicPlayerController.prepareToPlay { e in
                guard let e = e as? MPError else {
                    self.musicPlayerController.play()
                    return
                }
                switch e.code {
                case MPError.Code.cloudServiceCapabilityMissing:
                    print("AppleMusicPlayer#play: cloudServiceCapabilityMissing")
                    self.notify(.didPlayToEndTime)
                case MPError.Code.networkConnectionFailed:
                    print("AppleMusicPlayer#play: networkConnectionFailed")
                    self.notify(.errorOccured)
                case MPError.Code.notFound:
                    print("AppleMusicPlayer#play: notFound")
                    self.notify(.didPlayToEndTime)
                case MPError.Code.notSupported:
                    print("AppleMusicPlayer#play: notSupported")
                    self.notify(.didPlayToEndTime)
                case MPError.Code.permissionDenied:
                    print("AppleMusicPlayer#play: permissionDenied")
                    self.notify(.didPlayToEndTime)
                case MPError.Code.cancelled:
                    print("AppleMusicPlayer#play: cancelled")
                    if self.state == .loadToPlay {
                        self.musicPlayerController.play()
                    }
                case MPError.Code.unknown:
                    print("AppleMusicPlayer#play: unknown")
                    self.notify(.errorOccured)
                case MPError.Code.requestTimedOut:
                    print("AppleMusicPlayer#play: unknown")
                    self.notify(.errorOccured)
                }
            }
        }
        musicPlayerController.play()
    }
    
    open func pause() {
        state = .pause
        musicPlayerController.pause()
    }

    func clearPlayer() {
        musicPlayerController.pause()
        timer?.invalidate()
        timer = nil
    }
    
    func preparePlayer() {
        guard let track = track, let id = track.appleMusicID, track.isValid else { return }
        if #available(iOS 10.1, *) {
            let descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: [id])
            descriptor.startItemID = id
            musicPlayerController.setQueue(with: descriptor)
        } else if #available(iOS 9.3, *) {
            musicPlayerController.setQueue(with: [id])
        } else  {
            let predicate = MPMediaPropertyPredicate(value: id,
                                               forProperty: MPMediaItemPropertyPersistentID,
                                            comparisonType: MPMediaPredicateComparison.contains)
            let query = MPMediaQuery.songs()
            query.addFilterPredicate(predicate)
            musicPlayerController.setQueue(with: query)
        }
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                           target: self,
                                         selector: #selector(self.updateTime),
                                         userInfo: nil,
                                          repeats: true)
        timer?.fire()
        musicPlayerController.currentPlaybackTime = 0.0
    }
}
