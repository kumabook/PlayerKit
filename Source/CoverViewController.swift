//
//  CoverViewController.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 3/3/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import SnapKit

open class CoverViewController: UIViewController {
    let duration = 0.35
    let maxSpeed: CGFloat = 500
    open static var toggleAnimationDuration: Double = 0.25
    public enum TransitionMode {
        case slide
        case zoom
    }
    fileprivate var touchPointQueue: TouchPointQueue = TouchPointQueue()
    fileprivate var rate:       CGFloat = 0
    open var state: CeilingViewControllerState = .minimized
    open var ceilingViewController: CeilingViewController!
    open var floorViewController: UIViewController!
    open var transitionMode: TransitionMode = TransitionMode.slide

    public init(ceilingViewController: CeilingViewController, floorViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.ceilingViewController = ceilingViewController
        self.floorViewController = floorViewController
        self.ceilingViewController.coverViewController = self
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func loadView() {
        super.loadView()
        view.addSubview(floorViewController.view)
        view.addSubview(ceilingViewController.view)
        floorViewController.view.frame = view.frame
        ceilingViewController.view.clipsToBounds   = true
        let panGestureRecognizer = UIPanGestureRecognizer(target:self, action:#selector(CoverViewController.dragged(_:)))
        ceilingViewController.addGestureRecognizer(panGestureRecognizer)
    }

    @objc func dragged(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            state = .dragging
            if let _ = sender.view {
                touchPointQueue.clear()
            }
        case .changed:
            if let targetView = sender.view {
                let point = sender.translation(in: targetView)
                let frame = ceilingViewController.view.frame
                switch transitionMode {
                case .slide:
                    touchPointQueue.enqueue(sender.location(in: view), date: Date())
                    let h = ceilingViewController.tabHeight
                    let height = view.frame.height
                    let y = min(max(frame.minY + point.y, -h), height - h)
                    let rect = CGRect(x: 0, y: y, width: frame.width, height: height + h)
                    rate = 1 - abs(rect.minY) / frame.height
                    resizeCoverView(rect, actualRate: rate)
                    sender.setTranslation(CGPoint.zero, in:targetView)
                    if point.y < 0 { state = .dragging }
                    else           { state = .dragging }
                case .zoom:
                    let newSize: CGSize = CGSize(width: frame.width + point.x, height: frame.height - point.y)
                    let (w, h, actualRate) = calculateCoverViewActualRate(newSize)
                    rate = actualRate
                    let f                  = view.frame
                    resizeCoverView(CGRect(x: 0, y: f.height - h, width: w, height: h), actualRate: rate)
                    sender.setTranslation(CGPoint.zero, in: targetView)
                    if point.x > 0 || point.y < 0 { state = .dragging }
                    else                          { state = .dragging }
                }
            }
        case .ended:
            if let _ = sender.view {
                let speed = touchPointQueue.speed()
                if speed.y > maxSpeed {
                    minimizeCeilingView(true)
                } else if speed.y < -maxSpeed{
                    maximizeCeilingView(true)
                } else if rate < 0.5 {
                    minimizeCeilingView(true)
                } else {
                    maximizeCeilingView(true)
                }
            }
        case .cancelled: break
        case .failed:    break
        case .possible:  break
        }
    }

    open func minimizeCeilingView(_ animated: Bool) {
        let f = view.frame
        let w = ceilingViewController.minThumbnailWidth
        let h = ceilingViewController.minThumbnailHeight
        let y = f.height - h
        let action = {
            switch self.transitionMode {
            case .slide:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: f.height - h, width:  w, height: f.height + h)
            case .zoom:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: y, width:  w, height: h)
            }
            self.ceilingViewController.viewDidResize(0)
        }
        if animated {
            UIView.animate(withDuration: duration, delay: 0, options:UIViewAnimationOptions(), animations: action, completion: { finished in
                self.state = .minimized
                self.ceilingViewController.viewDidMinimize()
            })
        } else {
            action()
            self.state = .minimized
            self.ceilingViewController.viewDidMinimize()
        }
    }

    open func maximizeCeilingView(_ animated: Bool) {
        let f = view.frame
        let w = f.width
        let h = self.ceilingViewController.minThumbnailHeight
        let d = animated ? duration : 0
        UIView.animate(withDuration: d, delay: 0, options:UIViewAnimationOptions(), animations: {
            switch self.transitionMode {
            case .slide:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: -h, width: w, height: f.height + h)
            case .zoom:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: -h, width: w, height: h)
            }
            self.ceilingViewController.viewDidResize(1)
        }, completion: { finished in
            self.state = .maximized
            self.ceilingViewController.viewDidMaximize()
        })
    }

    open func toggleScreen() {
        switch state {
        case .maximized:
            state = .animating
            minimizeCeilingView(true)
        case .minimized:
            state = .animating
            maximizeCeilingView(true)
        case .hidden: break
        case .animating, .dragging: break
        }
    }

    func calculateCoverViewActualRate(_ newSize: CGSize) -> (CGFloat, CGFloat, CGFloat) {
        if  transitionMode == TransitionMode.slide {
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

    open func resizeCoverView(_ newRect: CGRect, actualRate: CGFloat) {
        ceilingViewController.view.frame = newRect
        ceilingViewController.viewDidResize(actualRate)
    }

    open func showCoverViewController(_ animated: Bool, completion: @escaping () -> () = {}) {
        let action = {
            let frame = self.ceilingViewController.view.frame
            let f     = self.view.frame
            let h     = self.ceilingViewController.minThumbnailHeight
            switch self.transitionMode {
            case .slide:
                let rect = CGRect(x: 0, y: f.height - h, width: frame.width, height: f.height + h)
                self.rate = 1 - abs(rect.minY) / frame.height
                self.resizeCoverView(rect, actualRate: self.rate)
                self.ceilingViewController.view.frame = rect
            case .zoom:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: h, width: frame.width, height: frame.height)
                self.ceilingViewController.viewDidResize(0)
            }
        }
        if animated {
            let d = CoverViewController.toggleAnimationDuration
            UIView.animate(withDuration: d, delay: 0, options:UIViewAnimationOptions(), animations: action, completion: { _ in
                self.state = .minimized
                self.ceilingViewController.viewDidMinimize()
                completion()
            })
        } else {
            action()
            self.state = .minimized
            self.ceilingViewController.viewDidMinimize()
            completion()
        }
    }

    open func hideCoverViewController(_ animated: Bool, completion: () -> () = {}) {
        let action = {
            let frame = self.ceilingViewController.view.frame
            let f     = self.view.frame
            let h     = self.ceilingViewController.minThumbnailHeight
            switch self.transitionMode {
            case .slide:
                let rect = CGRect(x: 0, y: f.height + h, width: frame.width, height: f.height + h)
                self.ceilingViewController.view.frame = rect
                self.ceilingViewController.viewDidResize(0)
            case .zoom:
                self.ceilingViewController.view.frame = CGRect(x: 0, y: h, width: frame.width, height: frame.height)
                self.ceilingViewController.viewDidResize(0)
            }
        }
        if animated {
            let d = CoverViewController.toggleAnimationDuration
            UIView.animate(withDuration: d, delay: 0, options:UIViewAnimationOptions(), animations: action, completion: { _ in })
            self.state = .hidden
            completion()
        } else {
            action()
            self.state = .hidden
            completion()
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        minimizeCeilingView(false)
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension CoverViewController: CoverViewControllerType {
    public func toggleCeilingView(_ animated: Bool) {
        toggleScreen()
    }
    public func minimizeCeilingView() {
        minimizeCeilingView(true)
    }
    public func maximizeCeilingView() {
        maximizeCeilingView(true)
    }
    public var ceilingViewControllerState: CeilingViewControllerState {
        return state
    }
}
