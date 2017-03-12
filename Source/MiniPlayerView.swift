//
//  MiniPlayerView.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 12/29/14.
//  Copyright (c) 2014 Hiroki Kumamoto. All rights reserved.
//

import UIKit

open class MiniPlayerView: UIView {
    open var delegate: MiniPlayerViewDelegate?
    open var state: PlayerState = .pause {
        didSet { updatePlayButton() }
    }

    public required override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    open func updateViewWithPlayer(_: QueuePlayer?) {
    }
    open func updateViewWithRate(_ rate: CGFloat) {
    }
    open func updatePlayButton() {
    }
    open override func updateConstraints() {
        super.updateConstraints()
    }
}
