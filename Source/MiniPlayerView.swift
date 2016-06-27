//
//  MiniPlayerView.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 12/29/14.
//  Copyright (c) 2014 Hiroki Kumamoto. All rights reserved.
//

import UIKit

public class MiniPlayerView: UIView {
    public var delegate: MiniPlayerViewDelegate?
    public var state: PlayerState = .Pause {
        didSet { updatePlayButton() }
    }

    public required override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public func updateViewWithPlayer(_: Player?) {
    }
    public func updateViewWithRate(rate: CGFloat) {
    }
    public func updatePlayButton() {
    }
    public override func updateConstraints() {
        super.updateConstraints()
    }
}
