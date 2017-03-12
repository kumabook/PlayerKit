//
//  PlayerView.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 3/2/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import AVFoundation

open class PlayerViewObserver: NSObject, Observer {
    public typealias Event = PlayerViewEvent
    open func listen(_ event: Event) {
    }
}

public enum PlayerViewEvent {
    case previous
    case next
    case toggle
    case close
    case timeChanged(CMTime)
    case message(String)
}

public protocol PlayerViewControllerType {
    func updateViewWithTrack(_ track: Track, animated: Bool)
    func timeUpdated()
    func enablePlayerView()
    func disablePlayerView()
    mutating func addObserver(_ observer: PlayerViewObserver)
    mutating func removeObserver(_ observer: PlayerViewObserver)
    var view: UIView! { get }
    init(player: QueuePlayer)
}

open class PlayerViewController: UIViewController, Observable, PlayerViewControllerType {
    public typealias ObserverType = PlayerViewObserver
    public typealias EventType    = PlayerViewEvent
    open var player: QueuePlayer!

    public required init(player: QueuePlayer) {
        super.init(nibName: nil, bundle: nil)
        self.player = player
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    fileprivate var _observers: [ObserverType] = []
    open  var  observers: [ObserverType] {
        get { return _observers }
        set { _observers = newValue }
    }
    
    open func updateViewWithTrack(_ track: Track, animated: Bool) {}
    open func timeUpdated() {}
    open func enablePlayerView() {}
    open func disablePlayerView() {}
}
