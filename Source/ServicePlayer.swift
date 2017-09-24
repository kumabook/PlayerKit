//
//  ServicePlayer.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/03/09.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation

public protocol ServicePlayer: class, Player, Observable where EventType == ServicePlayerEvent, ObserverType == ServicePlayerObserver {
    var track:             Track? { get set }
}

open class ServicePlayerObserver: NSObject, Observer {
    public typealias Event = ServicePlayerEvent
    open func listen(_ event: Event) {
    }
}

public func ==(lhs: ServicePlayerObserver, rhs: ServicePlayerObserver) -> Bool {
    return lhs.isEqual(rhs)
}

public enum ServicePlayerEvent {
    case timeUpdated
    case didPlayToEndTime
    case statusChanged
    case errorOccured
}

public extension ServicePlayer {
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
