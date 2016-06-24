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

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initializeSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeSubviews()
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setNeedsUpdateConstraints()
    }

    public func createSubviews() {
        durationLabel   = UILabel(frame: CGRectMake( 0, 0,  64, 20))
        titleLabel      = UILabel(frame: CGRectMake( 0, 0, 120, 20))
        playButton      = UIButton(type: UIButtonType.System)
        previousButton  = UIButton(type: UIButtonType.System)
        nextButton      = UIButton(type: UIButtonType.System)
    }

    public override func updateConstraints() {
        super.updateConstraints()
        durationLabel.removeConstraints(durationLabel.constraints)
        titleLabel.removeConstraints(titleLabel.constraints)
        playButton.removeConstraints(playButton.constraints)
        previousButton.removeConstraints(previousButton.constraints)
        nextButton.removeConstraints(nextButton.constraints)

        durationLabel.snp_makeConstraints { make in
            make.right.equalTo(self.snp_right).offset(-self.paddingSide)
            make.bottom.equalTo(self.snp_bottom).offset(-self.paddingSide)
        }
        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(self.nextButton.snp_right).offset(self.paddingSide)
            make.right.equalTo(self.snp_right).offset(-self.paddingSide)
            make.top.equalTo(self.snp_top).offset(self.paddingSide)
        }
        playButton.snp_makeConstraints { make in
            make.centerX.equalTo(self.snp_centerX)
            make.centerY.equalTo(self.snp_centerY)
            make.width.equalTo(self.buttonSize * 3/5)
            make.height.equalTo(self.buttonSize * 3/5)
        }
        previousButton.snp_makeConstraints { make in
            make.centerY.equalTo(self.snp_centerY)
            make.right.equalTo(self.playButton.snp_left).offset(-self.buttonPadding)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        nextButton.snp_makeConstraints { make in
            make.centerY.equalTo(self.snp_centerY)
            make.left.equalTo(self.playButton.snp_right).offset(self.buttonPadding)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
    }

    internal func initializeSubviews() {
        createSubviews()
        let bundle = NSBundle(identifier: "io.kumabook.PlayerKit")
        backgroundColor = UIColor.darkGrayColor()

        addSubview(durationLabel)
        addSubview(titleLabel)
        addSubview(playButton)
        addSubview(previousButton)
        addSubview(nextButton)

        durationLabel.font          = UIFont.boldSystemFontOfSize(15.0)
        durationLabel.textColor     = UIColor.whiteColor()
        durationLabel.text          = "00:00"
        durationLabel.textAlignment = NSTextAlignment.Right

        titleLabel.font          = UIFont.boldSystemFontOfSize(15.0)
        titleLabel.textColor     = UIColor.whiteColor()
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        titleLabel.text          = "No Track"
        titleLabel.textAlignment = NSTextAlignment.Right

        playButton.contentMode = UIViewContentMode.ScaleToFill
        playButton.tintColor   = UIColor.whiteColor()

        previousButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        previousButton.setImage(UIImage(named: "previous", inBundle: bundle, compatibleWithTraitCollection: nil), forState: [])
        previousButton.tintColor   = UIColor.whiteColor()

        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.setImage(UIImage(named: "next", inBundle: bundle, compatibleWithTraitCollection: nil), forState: [])
        nextButton.tintColor   = UIColor.whiteColor()

        playButton.addTarget(    self, action: #selector(MiniPlayerView.playButtonTapped),     forControlEvents: UIControlEvents.TouchUpInside)
        previousButton.addTarget(self, action: #selector(MiniPlayerView.previousButtonTapped), forControlEvents: UIControlEvents.TouchUpInside)
        nextButton.addTarget(    self, action: #selector(MiniPlayerView.nextButtonTapped),     forControlEvents: UIControlEvents.TouchUpInside)

        playButton.setImage(UIImage(named: "play", inBundle: bundle, compatibleWithTraitCollection: nil), forState: UIControlState.Normal)
        self._state = .Pause
    }

    internal func updatePlayButton() {
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
