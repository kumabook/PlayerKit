//
//  Observable.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/18/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import Foundation

public protocol Observer: Equatable {
    associatedtype EventType
    func listen(event: EventType)
}

public protocol Observable {
    associatedtype ObserverType: Observer
    associatedtype EventType
    var observers: [ObserverType] { get set}
    mutating func addObserver(observer: ObserverType)
    mutating func removeObserver(observer: ObserverType)
    func notify(event: EventType)
}

extension Observable where EventType == ObserverType.EventType {
    mutating public func addObserver(observer: ObserverType) {
        var os = observers
        os.append(observer)
        observers = os
    }
    mutating public func removeObserver(observer: ObserverType) {
        guard let i = observers.indexOf(observer) else { return }
        observers.removeAtIndex(i)
    }
    public func notify(event: EventType) {
        for o in observers {
            o.listen(event)
        }
    }
}
