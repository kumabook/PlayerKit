//
//  AppleMusicPlayer.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/03/09.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation
import MediaPlayer

class AppleMusicPlayer: ConcreteQueuePlayer {
    typealias ObserverType = QueuePlayerObserver
    typealias EventType    = QueuePlayerEvent
    fileprivate var _observers: [ObserverType] = []
    open  var  observers: [ObserverType] {
        get { return _observers }
        set { _observers = newValue }
    }
    public fileprivate(set) var musicPlayerController: MPMusicPlayerController?

    internal var tracks:       TrackList
    internal var trackIndex:   Int = -1
    internal var itemIndex:    Int = -1
    fileprivate var itemCount:    Int = 0
    fileprivate var timeObserver: AnyObject?
    
    fileprivate var statusProxy: ObserverProxy?
    fileprivate var endProxy:    ObserverProxy?
    fileprivate var timer:       Timer?
    internal var state: PlayerState {
        if let player = musicPlayerController {
            switch player.playbackState {
            case .playing:         return .play
            case .paused:          return .pause
            case .stopped:         return .pause
            case .interrupted:     return .pause
            case .seekingBackward: return .load
            case .seekingForward:  return .load
            }
        }
        return .init
    }
    
    init() {
        tracks        = TrackList(id: "",  tracks: [])
        statusProxy   = ObserverProxy(name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
                                   closure: self.playbackStateDidChange)
        endProxy      = ObserverProxy(name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
                                   closure: self.nowPlayingItemDidChange)
    }
    
    // MARK: Notification handler
    func nowPlayingItemDidChange(_ notification: Notification) {
        guard let player = musicPlayerController else { return }
        notify(.trackUnselected(currentTrack!, currentIndex!))
        itemIndex = (itemIndex + 1) % itemCount
        guard let _ = player.nowPlayingItem else {
            notify(.nextRequested)
            return
        }
    }
    
    func playbackStateDidChange(_ notification: Notification) {
        notify(.statusChanged)
    }
    
    @objc func updateTime() {
        if let _ = musicPlayerController {
            notify(.timeUpdated)
        }
    }
    
    // MARK: QueuePlayer protocol
    var playerType:  PlayerType     { return PlayerType.appleMusic }
    var playingInfo: PlayingInfo? {
        if let player = musicPlayerController, let item = player.nowPlayingItem {
            return PlayingInfo(duration: item.playbackDuration,
                            elapsedTime: player.currentPlaybackTime)
        }
        return nil
    }

    func seekToTime(_ time: TimeInterval) {
        musicPlayerController?.currentPlaybackTime = time
        notify(.timeUpdated)
    }
    
    open func keepPlaying() {
        if state.isPlaying {
            musicPlayerController?.pause()
            musicPlayerController?.play()
        }
    }
    
    func play() {
        guard let player = musicPlayerController else { return }
        if #available(iOS 10.1, *) {
            player.prepareToPlay { e in
                if let e = e as? MPError {
                    switch e.code {
                    case MPError.Code.cloudServiceCapabilityMissing:
                        print("AppleMusicPlayer: cloudServiceCapabilityMissing")
                    case MPError.Code.networkConnectionFailed:
                        print("AppleMusicPlayer: networkConnectionFailed")
                    case MPError.Code.notFound:
                        print("AppleMusicPlayer: notFound")
                    case MPError.Code.notSupported:
                        print("AppleMusicPlayer: notSupported")
                    case MPError.Code.permissionDenied:
                        print("AppleMusicPlayer: permissionDenied")
                    case MPError.Code.cancelled:
                        print("AppleMusicPlayer: cancelled")
                    case MPError.Code.unknown:
                        print("AppleMusicPlayer: unknown")
                    }
                }
                player.play()
            }
        } else {
            player.play()
        }
    }
    
    open func pause() {
        if let player = musicPlayerController {
            player.pause()
        }
    }

    func clearPlayer() {
        musicPlayerController?.pause()
        musicPlayerController?.endGeneratingPlaybackNotifications()
        timer?.invalidate()
        timer                 = nil
        musicPlayerController = nil
    }
    
    func preparePlayer() {
        var ids: [String] = []
        itemCount = 0
        itemIndex = 0
        for i in 0..<tracks.count {
            if let id = tracks[i].appleMusicID, tracks[i].isValid {
                itemCount += 1
                if i >= trackIndex {
                    ids.append(id)
                } else {
                    itemIndex += 1
                }
            }
        }
        if itemIndex >= itemCount {
            itemIndex = itemCount - 1
        }
        musicPlayerController = MPMusicPlayerController.applicationMusicPlayer()
        musicPlayerController?.beginGeneratingPlaybackNotifications()
        if #available(iOS 10.1, *) {
            let descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: ids)
            descriptor.startItemID = ids[0]
            musicPlayerController?.setQueueWith(descriptor)
        } else {
            if #available(iOS 9.3, *) {
                musicPlayerController?.setQueueWithStoreIDs(ids)
            } else {
            }
        }
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                           target: self,
                                         selector: #selector(self.updateTime),
                                         userInfo: nil,
                                          repeats: true)
        timer?.fire()
        musicPlayerController?.currentPlaybackTime = 0.0
    }
}
