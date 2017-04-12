//
//  TouchPointQueue.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/04/11.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation
import UIKit

public class TouchPointQueue {
    public fileprivate(set) var points: [(CGPoint, Date)]
    fileprivate var capacity: Int = 10
    public init(capacity: Int = 10) {
        self.capacity = capacity
        self.points = []
    }
    public func enqueue(_ point: CGPoint, date: Date) {
        points.insert((point, date), at: 0)
        if points.count >= capacity {
            points.removeLast()
        }
    }
    public var length: Int {
        return points.count
    }
    public func clear() {
        points.removeAll()
    }
    public func diff() -> (CGPoint, CGFloat) {
        guard let f = points.first, let l = points.last else { return (CGPoint(x: 0, y: 0), 0) }
        let dx = l.0.x - f.0.x
        let dy = l.0.y - f.0.y
        let t = CGFloat(l.1.timeIntervalSince(f.1))
        return (CGPoint(x: dx, y: dy), t)
    }
    public func distance() -> CGPoint {
        return diff().0
    }
    public func speed() -> CGPoint {
        let d = diff()
        return CGPoint(x: d.0.x / d.1, y: d.0.y / d.1)
    }
}
