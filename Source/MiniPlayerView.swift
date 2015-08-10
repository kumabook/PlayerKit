//
//  MiniPlayerView.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 12/29/14.
//  Copyright (c) 2014 Hiroki Kumamoto. All rights reserved.
//

import UIKit

public class MiniPlayerView: UIView {
    @IBOutlet public weak var durationLabel:  UILabel!
    @IBOutlet public weak var titleLabel:     UILabel!
    @IBOutlet public weak var playButton:     UIButton!
    @IBOutlet public weak var previousButton: UIButton!
    @IBOutlet public weak var nextButton:     UIButton!
    public var delegate:       MiniPlayerViewDelegate?
    private var _state: PlayerState = .Pause
    public var state: PlayerState {
        get { return _state }
        set(newState) { _state = newState; updatePlayButton() }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        baseInit()
    }
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        baseInit()
    }
    
    func baseInit() {
        let bundle = NSBundle(identifier: "io.kumabook.PlayerKit")
        let view = bundle!.loadNibNamed("MiniPlayerView", owner:self, options:nil)[0] as! UIView
        view.frame = self.bounds;
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth|UIViewAutoresizing.FlexibleHeight;
        self.addSubview(view)
        self.playButton.addTarget(    self, action: "playButtonTapped",     forControlEvents: UIControlEvents.TouchUpInside)
        self.previousButton.addTarget(self, action: "previousButtonTapped", forControlEvents: UIControlEvents.TouchUpInside)
        self.nextButton.addTarget(    self, action: "nextButtonTapped",     forControlEvents: UIControlEvents.TouchUpInside)

        playButton.setImage(UIImage(named: "play", inBundle: bundle, compatibleWithTraitCollection: nil), forState: UIControlState.Normal)
        self._state = .Pause
    }

    func updatePlayButton() {
        let bundle = NSBundle(identifier: "io.kumabook.PlayerKit")
        if state.isPlaying {
            playButton.setImage(UIImage(named: "pause", inBundle: bundle, compatibleWithTraitCollection: nil),  forState: UIControlState.Normal)
        } else {
            playButton.setImage(UIImage(named: "play", inBundle: bundle, compatibleWithTraitCollection: nil), forState: UIControlState.Normal)
        }
    }
    
    func playButtonTapped() {
        delegate?.miniPlayerViewPlayButtonTouched()
    }
    
    func previousButtonTapped() {
        delegate?.miniPlayerViewPreviousButtonTouched()
    }
    
    func nextButtonTapped() {
        delegate?.miniPlayerViewNextButtonTouched()
    }
}
