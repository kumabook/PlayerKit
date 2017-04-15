//
//  CeilingViewController.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/04/15.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation
import UIKit

public protocol CoverViewControllerType {
    func minimizeCeilingView(_ animated: Bool)
    func maximizeCeilingView(_ animated: Bool)
    func toggleCeilingView(_ animated: Bool)
    var ceilingViewControllerState: CeilingViewControllerState { get }
}

public enum CeilingViewControllerState {
    case hidden
    case maximized
    case minimized
    case dragging
    case animating
}

public protocol CeilingViewController {
    var view:               UIView! { get }
    var tabHeight:          CGFloat { get }
    var minThumbnailWidth:  CGFloat { get }
    var minThumbnailHeight: CGFloat { get }

    var coverViewController: CoverViewControllerType? { get set }
    
    func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer)
    func canSwipeCeilingView(touch: UITouch) -> Bool
    
    func viewDidResize(_ rate: CGFloat)
    func viewWillMinimize()
    func viewDidMinimize()
    func viewWillMaximize()
    func viewDidMaximize()
}

public extension CeilingViewController {
    func viewDidResize(_ rate: CGFloat) {}
    func viewWillMinimize() {}
    func viewDidMinimize() {}
    func viewWillMaximize() {}
    func viewDidMaximize() {}
}
