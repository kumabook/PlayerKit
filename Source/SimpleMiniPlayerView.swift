//
//  SimpleMiniPlayerView.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/25/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import UIKit

open class SimpleMiniPlayerView: MiniPlayerView {
    open var durationLabel:  UILabel!
    open var titleLabel:     UILabel!
    open var playButton:     UIButton!
    open var previousButton: UIButton!
    open var nextButton:     UIButton!
    let paddingSide:   CGFloat =  8.0
    let buttonSize:    CGFloat = 40.0
    let buttonPadding: CGFloat = 20.0
    
    public required init(frame: CGRect) {
        super.init(frame: frame)
        initializeSubviews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeSubviews()
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setNeedsUpdateConstraints()
    }
    
    open func createSubviews() {
        durationLabel   = UILabel(frame: CGRect( x: 0, y: 0,  width: 64, height: 20))
        titleLabel      = UILabel(frame: CGRect( x: 0, y: 0, width: 120, height: 20))
        playButton      = UIButton(type: UIButtonType.system)
        previousButton  = UIButton(type: UIButtonType.system)
        nextButton      = UIButton(type: UIButtonType.system)
    }
    
    open override func updateConstraints() {
        super.updateConstraints()
        durationLabel.removeConstraints(durationLabel.constraints)
        titleLabel.removeConstraints(titleLabel.constraints)
        playButton.removeConstraints(playButton.constraints)
        previousButton.removeConstraints(previousButton.constraints)
        nextButton.removeConstraints(nextButton.constraints)
        
        durationLabel.snp.makeConstraints { make in
            make.right.equalTo(self.snp.right).offset(-self.paddingSide)
            make.bottom.equalTo(self.snp.bottom).offset(-self.paddingSide)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.nextButton.snp.right).offset(self.paddingSide)
            make.right.equalTo(self.snp.right).offset(-self.paddingSide)
            make.top.equalTo(self.snp.top).offset(self.paddingSide)
        }
        playButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        previousButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.snp.centerY)
            make.right.equalTo(self.playButton.snp.left).offset(-self.buttonPadding)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        nextButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.snp.centerY)
            make.left.equalTo(self.playButton.snp.right).offset(self.buttonPadding)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
    }
    
    internal func initializeSubviews() {
        createSubviews()
        let bundle = Bundle(identifier: "io.kumabook.PlayerKit")
        backgroundColor = UIColor.darkGray

        addSubview(durationLabel)
        addSubview(titleLabel)
        addSubview(playButton)
        addSubview(previousButton)
        addSubview(nextButton)
        
        durationLabel.font          = UIFont.boldSystemFont(ofSize: 15.0)
        durationLabel.textColor     = UIColor.white
        durationLabel.text          = "00:00"
        durationLabel.textAlignment = NSTextAlignment.right
        
        titleLabel.font          = UIFont.boldSystemFont(ofSize: 15.0)
        titleLabel.textColor     = UIColor.white
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        titleLabel.text          = "No Track"
        titleLabel.textAlignment = NSTextAlignment.right
        
        playButton.contentMode = UIViewContentMode.scaleToFill
        playButton.tintColor   = UIColor.white
        
        previousButton.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        previousButton.setImage(UIImage(named: "previous", in: bundle, compatibleWith: nil), for: [])
        previousButton.tintColor   = UIColor.white
        
        nextButton.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        nextButton.setImage(UIImage(named: "next", in: bundle, compatibleWith: nil), for: [])
        nextButton.tintColor   = UIColor.white
        
        playButton.addTarget(    self, action: #selector(SimpleMiniPlayerView.playButtonTapped),     for: UIControlEvents.touchUpInside)
        previousButton.addTarget(self, action: #selector(SimpleMiniPlayerView.previousButtonTapped), for: UIControlEvents.touchUpInside)
        nextButton.addTarget(    self, action: #selector(SimpleMiniPlayerView.nextButtonTapped),     for: UIControlEvents.touchUpInside)
        
        playButton.setImage(UIImage(named: "play", in: bundle, compatibleWith: nil), for: UIControlState())
        state = .pause
    }
    
    open override func updateViewWithPlayer(_ player: Player?) {
        guard let player = player, let track = player.currentTrack else {
            titleLabel.text    = ""
            durationLabel.text = "00:00"
            return
        }
        titleLabel.text = track.title
        if let info = player.playingInfo {
            durationLabel.text = TimeHelper.timeStr(Float(info.elapsedTime))
        } else {
            durationLabel.text = "00:00"
        }
        state = player.state
    }

    open override func updateViewWithRate(_ rate: CGFloat) {
        let alpha = 0.75 * (1 - rate) + 0.25
        [titleLabel, durationLabel, playButton, previousButton, nextButton].forEach { $0.alpha = alpha }
    }

    open override func updatePlayButton() {
        let bundle = Bundle(identifier: "io.kumabook.PlayerKit")
        if state.isPlaying {
            playButton.setImage(UIImage(named: "pause", in: bundle, compatibleWith: nil),  for: UIControlState())
        } else {
            playButton.setImage(UIImage(named: "play", in: bundle, compatibleWith: nil), for: UIControlState())
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
