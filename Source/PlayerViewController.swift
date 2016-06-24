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
}

public protocol PlayerViewControllerType {
    func updateViewWithTrack(track: Track, player: Player, animated: Bool)
    func timeUpdated(player: Player)
    func enablePlayerView(player: Player)
    func disablePlayerView()
    mutating func addObserver(observer: PlayerViewObserver)
    mutating func removeObserver(observer: PlayerViewObserver)
    var view: UIView! { get }
    static func createPlayerViewController() -> PlayerViewController
}

public class PlayerViewController: UIViewController, Observable, PlayerViewControllerType {
    public typealias ObserverType = PlayerViewObserver
    public typealias EventType    = PlayerViewEvent
    
    private var _observers: [ObserverType] = []
    public  var  observers: [ObserverType] {
        get { return _observers }
        set { _observers = newValue }
    }
    
    public func updateViewWithTrack(track: Track, player: Player, animated: Bool) {}
    public func timeUpdated(player: Player) {}
    public func enablePlayerView(player: Player) {}
    public func disablePlayerView() {}
    public class func createPlayerViewController() -> PlayerViewController {
        return PlayerViewController()
    }
}
