//
//  DraggableCoverViewController.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 3/3/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import SnapKit

@objc public protocol DraggableCoverViewControllerDelegate {
    var view:               UIView! { get }
    var thumbnailView:      UIView  { get }
    var minThumbnailWidth:  CGFloat { get }
    var minThumbnailHeight: CGFloat { get }

    var draggableCoverViewController: DraggableCoverViewController? { get set }

    func didResizeCoverView(rate: CGFloat)
    func didMinimizedCoverView()
    func didMaximizedCoverView()
}

public class DraggableCoverViewController: UIViewController {
    let duration = 0.35
    let maxSpeed: CGFloat = 20
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
    private var startPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var startDate:  NSDate  = NSDate()
    private var rate:       CGFloat = 0
    public var state: State = .Minimized
    public var coverViewController: DraggableCoverViewControllerDelegate!
    public var floorViewController: UIViewController!
    public var transitionMode: TransitionMode = TransitionMode.Slide

    public init(coverViewController:DraggableCoverViewControllerDelegate, floorViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.coverViewController = coverViewController
        self.floorViewController = floorViewController
        self.coverViewController.draggableCoverViewController = self
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
        view.addSubview(coverViewController.view)
        floorViewController.view.frame = view.frame
        coverViewController.view.clipsToBounds   = true
        let panGestureRecognizer = UIPanGestureRecognizer(target:self, action:#selector(DraggableCoverViewController.dragged(_:)))
        coverViewController.view.addGestureRecognizer(panGestureRecognizer)
    }

    func dragged(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .Began:
            state = .Dragging
            if let targetView = sender.view {
                startPoint = sender.translationInView(targetView)
                startDate  = NSDate()
            }
        case .Changed:
            if let targetView = sender.view {
                let point = sender.translationInView(targetView)
                let frame = coverViewController.view.frame
                switch transitionMode {
                case .Slide:
                    let h = coverViewController.minThumbnailHeight
                    let y = max(frame.minY + point.y, -h)
                    let rect = CGRect(x: 0, y: y, width: frame.width, height: view.frame.height + h)
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
            if let targetView = sender.view {
                let point = sender.translationInView(targetView)
                let t = CGFloat(NSDate().timeIntervalSinceDate(startDate))
                let d = startPoint.y - point.y
                if abs(d) / t > maxSpeed {
                    if d > 0 { minimizeCoverView(true) }
                    else     { maximizeCoverView(true) }
                    return
                }
                if rate < 0.5 {
                    minimizeCoverView(true)
                } else {
                    maximizeCoverView(true)
                }
            }
        case .Cancelled: print("Cancelled")
        case .Failed:    print("Failed")
        case .Possible:  print("Possible")
        }
    }

    public func minimizeCoverView(animated: Bool) {
        let f = view.frame
        let w = coverViewController.minThumbnailWidth
        let h = coverViewController.minThumbnailHeight
        let y = f.height - h
        let action = {
            switch self.transitionMode {
            case .Slide:
                self.coverViewController.view.frame = CGRect(x: 0, y: f.height - h, width:  w, height: f.height + h)
            case .Zoom:
                self.coverViewController.view.frame = CGRect(x: 0, y: y, width:  w, height: h)
            }
            self.coverViewController.didResizeCoverView(0)
        }
        if animated {
            UIView.animateWithDuration(duration, delay: 0, options:.CurveEaseInOut, animations: action, completion: { finished in
                self.state = .Minimized
                self.coverViewController.didMinimizedCoverView()
            })
        } else {
            action()
            self.state = .Minimized
            self.coverViewController.didMinimizedCoverView()
        }
    }

    public func maximizeCoverView(animated: Bool) {
        let f = view.frame
        let w = f.width
        let h = self.coverViewController.minThumbnailHeight
        let d = animated ? duration : 0
        UIView.animateWithDuration(d, delay: 0, options:.CurveEaseInOut, animations: {
            switch self.transitionMode {
            case .Slide:
                self.coverViewController.view.frame = CGRect(x: 0, y: -h, width: w, height: f.height + h)
            case .Zoom:
                self.coverViewController.view.frame = CGRect(x: 0, y: -h, width: w, height: h)
            }
            self.coverViewController.didResizeCoverView(1)
        }, completion: { finished in
            self.state = .Maximized
            self.coverViewController.didMaximizedCoverView()
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
            let mintw = coverViewController.minThumbnailWidth
            let minth = coverViewController.minThumbnailHeight
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
        coverViewController.view.frame = newRect
        coverViewController.didResizeCoverView(actualRate)
    }

    public func showCoverViewController(animated: Bool, completion: () -> () = {}) {
        let action = {
            let frame = self.coverViewController.view.frame
            let f     = self.view.frame
            let h     = self.coverViewController.minThumbnailHeight
            switch self.transitionMode {
            case .Slide:
                let rect = CGRect(x: 0, y: f.height - h, width: frame.width, height: f.height + h)
                self.rate = 1 - abs(rect.minY) / frame.height
                self.resizeCoverView(rect, actualRate: self.rate)
                self.coverViewController.view.frame = rect
            case .Zoom:
                self.coverViewController.view.frame = CGRect(x: 0, y: h, width: frame.width, height: frame.height)
                self.coverViewController.didResizeCoverView(0)
            }
        }
        if animated {
            let d = DraggableCoverViewController.toggleAnimationDuration
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
            let frame = self.coverViewController.view.frame
            let f     = self.view.frame
            let h     = self.coverViewController.minThumbnailHeight
            switch self.transitionMode {
            case .Slide:
                let rect = CGRect(x: 0, y: f.height + h, width: frame.width, height: f.height + h)
                self.coverViewController.view.frame = rect
                self.coverViewController.didResizeCoverView(0)
            case .Zoom:
                self.coverViewController.view.frame = CGRect(x: 0, y: h, width: frame.width, height: frame.height)
                self.coverViewController.didResizeCoverView(0)
            }
        }
        if animated {
            let d = DraggableCoverViewController.toggleAnimationDuration
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
