//
//  ServicePlayer.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/03/09.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation

public protocol QueuePlayer {
    var playingInfo: PlayingInfo? { get }
    var playerType:  PlayerType { get }
    var state:       PlayerState { get }
    func clearPlayer()
    func preparePlayer()
    func pause()
    func play()
    func play(_ track: Track)
    func prepare(for: Track)
    func seekToTime(_ time: TimeInterval)
    func toggle()
}

public protocol ConcreteQueuePlayer: class, QueuePlayer, Observable {
    typealias ObserverType = QueuePlayerObserver
    typealias EventType    = QueuePlayerEvent
    var track:             Track? { get set }
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
    case errorOccured
}

public extension ConcreteQueuePlayer {
    func prepare(for track: Track) {
        self.track = track
        preparePlayer()
    }
    public func toggle() {
        if state.isPlaying {
            pause()
        } else {
            play()
        }
    }
    public func play(_ track: Track) {
        clearPlayer()
        prepare(for: track)
        play()
    }
}
