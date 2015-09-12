//
//  MiniPlayerView.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 12/29/14.
//  Copyright (c) 2014 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import SnapKit

public class MiniPlayerView: UIView {
    public var durationLabel:  UILabel!
    public var titleLabel:     UILabel!
    public var playButton:     UIButton!
    public var previousButton: UIButton!
    public var nextButton:     UIButton!
    let paddingSide:   CGFloat =  8.0
    let buttonSize:    CGFloat = 40.0
    let buttonPadding: CGFloat = 30.0
    public var delegate: MiniPlayerViewDelegate?
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
        backgroundColor = UIColor.darkGrayColor()
        durationLabel   = UILabel(frame: CGRectMake( 0, 0,  64, 20))
        titleLabel      = UILabel(frame: CGRectMake( 0, 0, 120, 20))
        playButton      = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        previousButton  = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        nextButton      = UIButton.buttonWithType(UIButtonType.System) as! UIButton

        addSubview(durationLabel)
        addSubview(titleLabel)
        addSubview(playButton)
        addSubview(previousButton)
        addSubview(nextButton)

        durationLabel.font      = UIFont.boldSystemFontOfSize(15.0)
        durationLabel.textColor = UIColor.whiteColor()
        durationLabel.snp_makeConstraints { make in
            make.right.equalTo(self.snp_right).offset(-self.paddingSide)
            make.bottom.equalTo(self.snp_bottom).offset(-self.paddingSide)
        }

        titleLabel.font          = UIFont.boldSystemFontOfSize(15.0)
        titleLabel.textColor     = UIColor.whiteColor()
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(self.nextButton.snp_right).offset(self.paddingSide)
            make.right.equalTo(self.snp_right).offset(-self.paddingSide)
            make.top.equalTo(self.snp_top).offset(self.paddingSide)
        }

        playButton.contentMode = UIViewContentMode.ScaleToFill
        playButton.tintColor   = UIColor.whiteColor()
        playButton.snp_makeConstraints { make in
            make.centerX.equalTo(self.snp_centerX)
            make.centerY.equalTo(self.snp_centerY)
            make.width.equalTo(self.buttonSize * 3/5)
            make.height.equalTo(self.buttonSize * 3/5)
        }

        previousButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        previousButton.setImage(UIImage(named: "previous", inBundle: bundle, compatibleWithTraitCollection: nil), forState: .allZeros)
        previousButton.tintColor   = UIColor.whiteColor()
        previousButton.snp_makeConstraints { make in
            make.centerY.equalTo(self.snp_centerY)
            make.right.equalTo(self.playButton.snp_left).offset(-self.buttonPadding)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }

        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.setImage(UIImage(named: "next", inBundle: bundle, compatibleWithTraitCollection: nil), forState: .allZeros)
        nextButton.tintColor   = UIColor.whiteColor()
        nextButton.snp_makeConstraints { make in
            make.centerY.equalTo(self.snp_centerY)
            make.left.equalTo(self.playButton.snp_right).offset(self.buttonPadding)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }

        playButton.addTarget(    self, action: "playButtonTapped",     forControlEvents: UIControlEvents.TouchUpInside)
        previousButton.addTarget(self, action: "previousButtonTapped", forControlEvents: UIControlEvents.TouchUpInside)
        nextButton.addTarget(    self, action: "nextButtonTapped",     forControlEvents: UIControlEvents.TouchUpInside)

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
