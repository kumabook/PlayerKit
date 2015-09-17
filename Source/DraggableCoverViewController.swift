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
    let duration = 0.5
    public enum State {
        case Maximized
        case Minimized
        case Dragging
        case Maximizing
        case Minimizing
    }
    public var state: State = .Minimized
    public var coverViewController: DraggableCoverViewControllerDelegate!
    public var floorViewController: UIViewController!

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
        coverViewController.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        let panGestureRecognizer = UIPanGestureRecognizer(target:self, action:"dragged:")
        coverViewController.view.addGestureRecognizer(panGestureRecognizer)
    }

    func dragged(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .Began:
            state = .Dragging
        case .Changed:
            if let targetView = sender.view {
                let point = sender.translationInView(targetView)
                resizeCoverView(coverViewController.view.frame.width + point.x)
                sender.setTranslation(CGPointZero, inView:targetView)
                if point.x > 0 || point.y < 0 { state = .Maximizing }
                else                          { state = .Minimizing }
            }
        case .Ended:
            switch state {
            case .Minimizing: minimizeCoverView(true)
            case .Maximizing: maximizeCoverView(true)
            default: break
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
        let d = animated ? duration : 0
        UIView.animateWithDuration(d, animations: {
            self.coverViewController.view.frame = CGRect(x: 0, y: y, width:  w, height: h)
            self.coverViewController.didResizeCoverView(0)
        }, completion: { finished in
            self.state = .Minimized
            self.coverViewController.didMinimizedCoverView()
        })
    }

    public func maximizeCoverView(animated: Bool) {
        let f = view.frame
        let w = f.width
        let h = f.height
        let d = animated ? duration : 0
        UIView.animateWithDuration(d, animations: {
            self.coverViewController.view.frame = CGRect(x: 0, y:  0, width: w, height:  h)
            self.coverViewController.didResizeCoverView(1)
        }, completion: { finished in
            self.state = .Maximized
            self.coverViewController.didMaximizedCoverView()
        })
    }

    public func toggleScreen() {
        switch state {
        case .Maximized:
            state = .Minimizing
            minimizeCoverView(true)
        case .Minimized:
            state = .Maximizing
            maximizeCoverView(true)
        default:
            break;
        }
    }

    func calculateCoverViewActualRate(newWidth: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        let  rate = newWidth / view.frame.width
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

    public func resizeCoverView(newWidth: CGFloat) {
        let f                  = view.frame
        let (w, h, actualRate) = calculateCoverViewActualRate(newWidth)

        coverViewController.view.frame = CGRect(x: 0, y: f.height - h, width: w, height: h)
        coverViewController.didResizeCoverView(actualRate)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        minimizeCoverView(false)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
