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

class NormalPlayer: QueuePlayer {
    typealias ObserverType = QueuePlayerObserver
    typealias EventType    = QueuePlayerEvent
    fileprivate var _observers: [ObserverType] = []
    open  var  observers: [ObserverType] {
        get { return _observers }
        set { _observers = newValue }
    }
    public fileprivate(set) var queuePlayer:  AVQueuePlayer?

    internal var tracks:       TrackList
    internal var trackIndex:   Int = -1
    internal var itemIndex:    Int = -1
    internal var state:        PlayerState
    fileprivate var itemCount:    Int = 0
    fileprivate var timeObserver: AnyObject?
    
    fileprivate var proxy:       AVQueuePlayerNotificationProxy
    fileprivate var statusProxy: ObserverProxy?
    fileprivate var endProxy:    ObserverProxy?
    
    init() {
        state         = .init
        proxy         = AVQueuePlayerNotificationProxy()
        tracks        = TrackList(id: "",  tracks: [])
        statusProxy   = ObserverProxy(name: AVQueuePlayerDidChangeStatusNotification, closure: self.playerDidChangeStatus);
        endProxy      = ObserverProxy(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue, closure: self.playerDidPlayToEndTime);
    }
    
    // MARK: Notification handler
    func playerDidPlayToEndTime(_ notification: Notification) {
        if let qp = queuePlayer, let item = qp.currentItem {
            qp.remove(item)
        }
        notify(.trackUnselected(currentTrack!, currentIndex!))
        itemIndex = (itemIndex + 1) % itemCount
        if itemIndex == 0 {
            notify(.nextRequested)
        } else {
            notify(.trackSelected(currentTrack!, currentIndex!))
        }
    }
    
    func playerDidChangeStatus(_ notification: Notification) {
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

    // MARK: QueuePlayer protocol
    var playerType:        PlayerType     { return PlayerType.normal }
    var currentTime:       TimeInterval?  {
        if let time = queuePlayer?.currentTime() {
            return Float64(time.value * 1000) / Float64(time.timescale)
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
        if let player = queuePlayer {
            if player.items().count == 0 {
                notify(.nextRequested)
            } else {
                player.play()
                if player.status == AVPlayerStatus.readyToPlay { state = .play }
                else                                           { state = .loadToPlay }
            }
        }
    }

    open func pause() {
        if let player = queuePlayer {
          player.pause()
          state = .pause
        }
    }

    func preparePlayer() {
        if let player = queuePlayer {
            player.pause()
            if let observer = timeObserver {
                player.removeTimeObserver(observer)
            }
            player.removeAllItems()
            player.removeObserver(proxy, forKeyPath: "status")
        }
        var _playerItems: [AVPlayerItem] = []
        itemCount = 0
        itemIndex = 0
        for i in 0..<tracks.count {
            print("\(i) \(tracks[i].title) \(tracks[i].isValid)")
            if let url = tracks[i].streamURL, tracks[i].isValid {
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
        queuePlayer = AVQueuePlayer(items: _playerItems)
        queuePlayer?.seek(to: kCMTimeZero)
        let time = CMTimeMakeWithSeconds(1.0, 1)
        timeObserver = queuePlayer?.addPeriodicTimeObserver(forInterval: time, queue: nil, using:self.updateTime) as AnyObject?
        queuePlayer?.addObserver(proxy, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
    }
}
