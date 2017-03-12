//
//  ObserverProxy.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/03/09.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation

class ObserverProxy {
    var closure: (Notification) -> ();
    var name: NSNotification.Name;
    var object: AnyObject?;
    var center: NotificationCenter { get { return NotificationCenter.default } }
    init(name: NSNotification.Name, closure: @escaping (Notification) -> ()) {
        self.closure = closure;
        self.name = name;
        self.start();
    }
    convenience init(name: NSNotification.Name, object: AnyObject, closure: @escaping (Notification) -> ()) {
        self.init(name: name, closure: closure);
        self.object = object;
    }
    deinit { stop() }
    func start() { center.addObserver(self, selector:#selector(ObserverProxy.handler(_:)), name: name, object: object) }
    func stop()  { center.removeObserver(self) }
    @objc func handler(_ notification: Notification) { closure(notification); }
}
