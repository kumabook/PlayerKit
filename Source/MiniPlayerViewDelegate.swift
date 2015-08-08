//
//  MiniPlayerViewDelegate.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 1/1/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit

protocol MiniPlayerViewDelegate {
    func miniPlayerViewPlayButtonTouched()     -> Void
    func miniPlayerViewPreviousButtonTouched() -> Void
    func miniPlayerViewNextButtonTouched()     -> Void
}
