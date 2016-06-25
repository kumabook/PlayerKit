//
//  PlayerView.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 3/2/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import AVFoundation

public class PlayerViewObserver: NSObject, Observer {
    public typealias Event = PlayerViewEvent
    public func listen(event: Event) {
    }
}

public func ==(lhs: PlayerViewObserver, rhs: PlayerObserver) -> Bool {
    return lhs.isEqual(rhs)
}

public enum PlayerViewEvent {
    case Previous
    case Next
    case Toggle
    case Close
    case TimeChanged(CMTime)
    case Message(String)
}

public protocol PlayerViewControllerType {
    func updateViewWithTrack(track: Track, animated: Bool)
    func timeUpdated()
    func enablePlayerView()
    func disablePlayerView()
    mutating func addObserver(observer: PlayerViewObserver)
    mutating func removeObserver(observer: PlayerViewObserver)
    var view: UIView! { get }
    init(player: Player)
}

public class PlayerViewController: UIViewController, Observable, PlayerViewControllerType {
    public typealias ObserverType = PlayerViewObserver
    public typealias EventType    = PlayerViewEvent
    public var player: Player!

    public required init(player: Player) {
        super.init(nibName: nil, bundle: nil)
        self.player = player
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private var _observers: [ObserverType] = []
    public  var  observers: [ObserverType] {
        get { return _observers }
        set { _observers = newValue }
    }
    
    public func updateViewWithTrack(track: Track, animated: Bool) {}
    public func timeUpdated() {}
    public func enablePlayerView() {}
    public func disablePlayerView() {}
}
