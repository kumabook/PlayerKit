//
//  CoverViewController.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 3/3/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import SnapKit

@objc public protocol CoverViewControllerDelegate {
    var view:               UIView! { get }
    var thumbnailView:      UIView  { get }
    var minThumbnailWidth:  CGFloat { get }
    var minThumbnailHeight: CGFloat { get }

    var coverViewController: CoverViewController? { get set }

    func didResizeCoverView(rate: CGFloat)
    func didMinimizedCoverView()
    func didMaximizedCoverView()
}

private class TouchPointQueue {
    private var points: [(CGPoint, NSDate)] = []
    private let capacity: Int = 10
    private func enqueue(point: CGPoint, date: NSDate) {
        points.insert((point, date), atIndex: 0)
        if points.count >= capacity {
            points.removeLast()
        }
    }
    private var length: Int {
        return points.count
    }
    private func clear() {
        points.removeAll()
    }
    private func diff() -> (CGPoint, CGFloat) {
        guard let f = points.first, l = points.last else { return (CGPoint(x: 0, y: 0), 0) }
        let dx = l.0.x - f.0.x
        let dy = l.0.y - f.0.y
        let t = CGFloat(l.1.timeIntervalSinceDate(f.1))
        return (CGPoint(x: dx, y: dy), t)
    }
    private func distance() -> CGPoint {
        return diff().0
    }
    private func speed() -> CGPoint {
        let d = diff()
        return CGPoint(x: d.0.x / d.1, y: d.0.y / d.1)
    }
}

public class CoverViewController: UIViewController {
    let duration = 0.35
    let maxSpeed: CGFloat = 500
    public static var toggleAnimationDuration: Double = 0.25
    public enum State {
        case Hidden
        case Maximized
        case Minimized
        case Dragging
        case Animating
    }
    public enum TransitionMode {
        case Slide
        case Zoom
    }
    private var touchPointQueue: TouchPointQueue = TouchPointQueue()
    private var rate:       CGFloat = 0
    public var state: State = .Minimized
    public var ceilingViewController: CoverViewControllerDelegate!
    public var floorViewController: UIViewController!
    public var transitionMode: TransitionMode = TransitionMode.Slide

    public init(ceilingViewController: CoverViewControllerDelegate, floorViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.ceilingViewController = ceilingViewController
        self.floorViewController = floorViewController
        self.ceilingViewController.coverViewController = self
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func loadView() {
        super.loadView()
        view.addSubview(floorViewController.view)
        view.addSubview(ceilingViewController.view)
        floorViewController.view.frame = view.frame
        ceilingViewController.view.clipsToBounds   = true
        let panGestureRecognizer = UIPanGestureRecognizer(target:self, action:#selector(CoverViewController.dragged(_:)))
        ceilingViewController.view.addGestureRecognizer(panGestureRecognizer)
    }

    func dragged(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .Began:
            state = .Dragging
            if let _ = sender.view {
                touchPointQueue.clear()
            }
        case .Changed:
            if let targetView = sender.view {
                let point = sender.translationInView(targetView)
                let frame = ceilingViewController.view.frame
                switch transitionMode {
                case .Slide:
                    touchPointQueue.enqueue(sender.locationInView(view), date: NSDate())
                    let h = ceilingViewController.minThumbnailHeight
                    let height = view.frame.height
                    let y = min(max(frame.minY + point.y, -h), height - h)
                    let rect = CGRect(x: 0, y: y, width: frame.width, height: height + h)
                    rate = 1 - abs(rect.minY) / frame.height
                    resizeCoverView(rect, actualRate: rate)
                    sender.setTranslation(CGPointZero, inView:targetView)
                    if point.y < 0 { state = .Dragging }
                    else           { state = .Dragging }
                case .Zoom:
                    let newSize: CGSize = CGSize(width: frame.width + point.x, height: frame.height - point.y)
                    let (w, h, actualRate) = calculateCoverViewActualRate(newSize)
                    rate = actualRate
                    let f                  = view.frame
                    resizeCoverView(CGRect(x: 0, y: f.height - h, width: w, height: h), actualRate: rate)
                    sender.setTranslation(CGPointZero, inView:targetView)
                    if point.x > 0 || point.y < 0 { state = .Dragging }
                    else                          { state = .Dragging }
                }
            }
        case .Ended:
            if let _ = sender.view {
                let speed = touchPointQueue.speed()
                if speed.y > maxSpeed {
                    minimizeCoverView(true)
                } else if speed.y < -maxSpeed{
                    maximizeCoverView(true)
                } else if rate < 0.5 {
                    minimizeCoverView(true)
                } else {
                    maximizeCoverView(true)
                }
            }
        case .Cancelled: break
        case .Failed:    break
        case .Possible:  break
        }
    }

    public func minimizeCoverView(animated: Bool) {
        let f = view.frame
        let w = ceilingViewController.minThumbnailWidth
        let h = ceilingViewController.minThumbnailHeight
        let y = f.height - h
        let action = {
            switch self.transitionMode {
            case .Slide:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: f.height - h, width:  w, height: f.height + h)
            case .Zoom:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: y, width:  w, height: h)
            }
            self.ceilingViewController.didResizeCoverView(0)
        }
        if animated {
            UIView.animateWithDuration(duration, delay: 0, options:.CurveEaseInOut, animations: action, completion: { finished in
                self.state = .Minimized
                self.ceilingViewController.didMinimizedCoverView()
            })
        } else {
            action()
            self.state = .Minimized
            self.ceilingViewController.didMinimizedCoverView()
        }
    }

    public func maximizeCoverView(animated: Bool) {
        let f = view.frame
        let w = f.width
        let h = self.ceilingViewController.minThumbnailHeight
        let d = animated ? duration : 0
        UIView.animateWithDuration(d, delay: 0, options:.CurveEaseInOut, animations: {
            switch self.transitionMode {
            case .Slide:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: -h, width: w, height: f.height + h)
            case .Zoom:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: -h, width: w, height: h)
            }
            self.ceilingViewController.didResizeCoverView(1)
        }, completion: { finished in
            self.state = .Maximized
            self.ceilingViewController.didMaximizedCoverView()
        })
    }

    public func toggleScreen() {
        switch state {
        case .Maximized:
            state = .Animating
            minimizeCoverView(true)
        case .Minimized:
            state = .Animating
            maximizeCoverView(true)
        case .Hidden: break
        case .Animating, .Dragging: break
        }
    }

    func calculateCoverViewActualRate(newSize: CGSize) -> (CGFloat, CGFloat, CGFloat) {
        if  transitionMode == TransitionMode.Slide {
            let  rate = newSize.height / view.frame.height
            return (view.frame.width, rate * view.frame.height, rate)
        } else {
            let  rate = newSize.width / view.frame.width
            let mintw = ceilingViewController.minThumbnailWidth
            let minth = ceilingViewController.minThumbnailHeight
            let     f = view.frame
            let width      = min(f.width, max(rate*f.width, mintw)) // mintw < width < f.width
                                                                    // width == thumbnail width and cover view width
            let actualRate = (width - mintw) / (f.width - mintw)
            let th         = width * minth / mintw                  // thumbnail height
            let height     = th + actualRate*(f.height - th)        // cover view height
            return (width, height, actualRate)
        }
    }

    public func resizeCoverView(newRect: CGRect, actualRate: CGFloat) {
        ceilingViewController.view.frame = newRect
        ceilingViewController.didResizeCoverView(actualRate)
    }

    public func showCoverViewController(animated: Bool, completion: () -> () = {}) {
        let action = {
            let frame = self.ceilingViewController.view.frame
            let f     = self.view.frame
            let h     = self.ceilingViewController.minThumbnailHeight
            switch self.transitionMode {
            case .Slide:
                let rect = CGRect(x: 0, y: f.height - h, width: frame.width, height: f.height + h)
                self.rate = 1 - abs(rect.minY) / frame.height
                self.resizeCoverView(rect, actualRate: self.rate)
                self.ceilingViewController.view.frame = rect
            case .Zoom:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: h, width: frame.width, height: frame.height)
                self.ceilingViewController.didResizeCoverView(0)
            }
        }
        if animated {
            let d = CoverViewController.toggleAnimationDuration
            UIView.animateWithDuration(d, delay: 0, options:.CurveEaseInOut, animations: action, completion: { _ in
                self.state = .Minimized
                completion()
            })
        } else {
            action()
            self.state = .Minimized
            completion()
        }
    }

    public func hideCoverViewController(animated: Bool, completion: () -> () = {}) {
        let action = {
            let frame = self.ceilingViewController.view.frame
            let f     = self.view.frame
            let h     = self.ceilingViewController.minThumbnailHeight
            switch self.transitionMode {
            case .Slide:
                let rect = CGRect(x: 0, y: f.height + h, width: frame.width, height: f.height + h)
                self.ceilingViewController.view.frame = rect
                self.ceilingViewController.didResizeCoverView(0)
            case .Zoom:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: h, width: frame.width, height: frame.height)
                self.ceilingViewController.didResizeCoverView(0)
            }
        }
        if animated {
            let d = CoverViewController.toggleAnimationDuration
            UIView.animateWithDuration(d, delay: 0, options:.CurveEaseInOut, animations: action, completion: { _ in })
            self.state = .Hidden
            completion()
        } else {
            action()
            self.state = .Hidden
            completion()
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        minimizeCoverView(false)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
