//
//  MiniPlayerViewDelegate.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 1/1/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit

public protocol MiniPlayerViewDelegate {
    func miniPlayerViewPlayButtonTouched()     -> Void
    func miniPlayerViewPreviousButtonTouched() -> Void
    func miniPlayerViewNextButtonTouched()     -> Void
    func miniPlayerViewUpdate()                -> Void
}
