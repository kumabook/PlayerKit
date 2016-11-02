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
    func listen(_ event: EventType)
}

public protocol Observable {
    associatedtype ObserverType: Observer
    associatedtype EventType
    var observers: [ObserverType] { get set}
    mutating func addObserver(_ observer: ObserverType)
    mutating func removeObserver(_ observer: ObserverType)
    func notify(_ event: EventType)
}

extension Observable where EventType == ObserverType.EventType {
    mutating public func addObserver(_ observer: ObserverType) {
        var os = observers
        os.append(observer)
        observers = os
    }
    mutating public func removeObserver(_ observer: ObserverType) {
        guard let i = observers.index(of: observer) else { return }
        observers.remove(at: i)
    }
    public func notify(_ event: EventType) {
        for o in observers {
            o.listen(event)
        }
    }
}
