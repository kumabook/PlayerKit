//
//  NormalPlayer.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/03/09.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation
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

class NormalPlayer: ServicePlayer {
    typealias ObserverType = ServicePlayerObserver
    typealias EventType    = ServicePlayerEvent
    fileprivate var _observers: [ObserverType] = []
    open        var  observers: [ObserverType] {
        get { return _observers }
        set { _observers = newValue }
    }
    public fileprivate(set) var queuePlayer:  AVQueuePlayer?

    internal var track: Track?
    internal var state: PlayerState {
        didSet {
            if oldValue != state {
                notify(.statusChanged)
            }
        }
    }

    fileprivate var timeObserver: Any?
    fileprivate var proxy:       AVQueuePlayerNotificationProxy
    fileprivate var statusProxy: ObserverProxy?
    fileprivate var endProxy:    ObserverProxy?
    
    init() {
        state         = .init
        proxy         = AVQueuePlayerNotificationProxy()
        track         = nil
        statusProxy   = ObserverProxy(name: NSNotification.Name(rawValue: AVQueuePlayerDidChangeStatusNotification),
                                   closure: self.playerDidChangeStatus)
        endProxy      = ObserverProxy(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                   closure: self.playerDidPlayToEndTime)
    }
    
    // MARK: Notification handler
    func playerDidPlayToEndTime(_ notification: Notification) {
        if let qp = queuePlayer, let item = qp.currentItem {
            qp.remove(item)
        }
        notify(.didPlayToEndTime)
    }
    
    func playerDidChangeStatus(_ notification: Notification) {
        guard let player = queuePlayer else { return }
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

    func updateTime(_ time: CMTime) {
        guard let _ = queuePlayer else { return }
        notify(.timeUpdated)
    }

    // MARK: QueuePlayer protocol
    var playerType: PlayerType { return PlayerType.normal }
    var playingInfo: PlayingInfo? {
        if let item = queuePlayer?.currentItem {
            return PlayingInfo(duration: CMTimeGetSeconds(item.duration),
                            elapsedTime: CMTimeGetSeconds(item.currentTime()))
        }
        return nil
    }

    func seekToTime(_ time: TimeInterval) {
        let preferredTimeScale: Int32 = 1000
        queuePlayer?.seek(to: CMTimeMakeWithSeconds(time, preferredTimeScale))
        notify(.timeUpdated)
    }

    open func keepPlaying() {
        if state.isPlaying {
            queuePlayer?.pause()
            queuePlayer?.play()
        }
    }

    func play() {
        guard let player = queuePlayer else { return }
        if player.items().count == 0 {
            notify(.didPlayToEndTime)
            return
        }
        player.play()
        if player.status == AVPlayerStatus.readyToPlay {
            state = .play
        } else {
            state = .loadToPlay
        }
    }

    open func pause() {
        guard let player = queuePlayer else { return }
        player.pause()
        state = .pause
    }
    
    func clearPlayer() {
        defer {
            timeObserver = nil
            queuePlayer  = nil
        }
        guard let player = queuePlayer else { return }
        player.pause()
        player.removeAllItems()
        player.removeObserver(proxy, forKeyPath: "status")
        guard let observer = timeObserver else { return }
        player.removeTimeObserver(observer)
    }

    func preparePlayer() {
        guard let track = track, let url = track.streamURL, track.isValid else { return }
        queuePlayer = AVQueuePlayer(items: [AVPlayerItem(url:url as URL)])
        queuePlayer?.seek(to: kCMTimeZero)
        let time = CMTimeMakeWithSeconds(1.0, 1)
        timeObserver = queuePlayer?.addPeriodicTimeObserver(forInterval: time, queue: nil, using:self.updateTime)
        queuePlayer?.addObserver(proxy, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
    }
}
