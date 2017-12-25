//
//  SimplePlayerViewController.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/24/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import AVFoundation
import UIKit

open class SimplePlayerViewController: PlayerViewController {
    enum State {
        case normal
        case dragging(CGPoint, Float)
        case changing(TimeInterval)
    }
    let priorityHigh                   = 750

    let paddingSide:           CGFloat = 16.0
    let paddingBottom:         CGFloat = 90.0
    let paddingTitleBottom:    CGFloat = 64.0
    let paddingSubTitleBottom: CGFloat = 40.0
    let paddingBottomTime:     CGFloat = 28.0
    let buttonSize:            CGFloat = 40.0
    let buttonPadding:         CGFloat = 30.0
    let sliderWidth:           CGFloat = 2.0
    let sliderHeight:          CGFloat = 32.0

    var toggleAnimationDuration: Double = 0.25
    var state: State = .normal
    
    open var imageView:           UIImageView!
    
    open var slider:              UISlider!
    open var previousButton:      UIButton!
    open var playButton:          UIButton!
    open var nextButton:          UIButton!
    open var closeButton:         UIButton!
    open var iconImage:           UIImage!
    open var titleLabel:          UILabel!
    open var subTitleLabel:       UILabel!
    open var currentLabel:        UILabel!
    open var totalLabel:          UILabel!
    open var imageEffectView:     UIVisualEffectView!
    open var imageCoverView:      UIView!
    open var videoEffectView:     UIVisualEffectView!

    open var sliderThumbImage: UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: sliderWidth, height: sliderHeight), false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(CGRect(x: 0, y: sliderHeight/4, width: sliderWidth, height: sliderHeight/2))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    public required init(player: QueuePlayer) {
        super.init(player: player)
        initializeSubviews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeSubviews()
    }

    open func initializeSubviews() {
        titleLabel     = UILabel()
        subTitleLabel  = UILabel()
        currentLabel   = UILabel()
        totalLabel     = UILabel()
        slider         = UISlider()
        nextButton     = UIButton(type: UIButtonType.system)
        playButton     = UIButton(type: UIButtonType.system)
        previousButton = UIButton(type: UIButtonType.system)
        
        closeButton    = UIButton(type: UIButtonType.system)
        
        titleLabel.text             = "title title"
        titleLabel.textAlignment    = NSTextAlignment.left
        subTitleLabel.text          = "subtitle subtitle"
        subTitleLabel.textAlignment = NSTextAlignment.left
        currentLabel.text           = "00:00"
        totalLabel.text             = "00:00"
        
        imageView  = UIImageView()
        videoView  = VideoView()
        imageEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        imageCoverView  = UIView()
        videoEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        
        titleLabel.textColor        = UIColor.white
        titleLabel.font             = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor        = UIColor.white
        titleLabel.textAlignment    = NSTextAlignment.left
        subTitleLabel.textColor     = UIColor.white
        subTitleLabel.textAlignment = NSTextAlignment.left
        currentLabel.textColor      = UIColor.white
        currentLabel.font           = UIFont.boldSystemFont(ofSize: 15)
        totalLabel.textColor        = UIColor.white
        totalLabel.font             = UIFont.boldSystemFont(ofSize: 15)
        
        nextButton.tintColor        = UIColor.white
        playButton.tintColor        = UIColor.white
        previousButton.tintColor    = UIColor.white
        
        closeButton.tintColor       = UIColor.white
        
        let bundle = Bundle(identifier: "io.kumabook.PlayerKit")
        let nextImage     = UIImage(named:     "next", in: bundle, compatibleWith: nil)
        let playImage     = UIImage(named:     "play", in: bundle, compatibleWith: nil)
        let previousImage = UIImage(named: "previous", in: bundle, compatibleWith: nil)
        let closeImage    = UIImage(named:    "close", in: bundle, compatibleWith: nil)
        nextButton.setImage(        nextImage, for: UIControlState())
        playButton.setImage(        playImage, for: UIControlState())
        previousButton.setImage(previousImage, for: UIControlState())
        closeButton.setImage(      closeImage, for: UIControlState())
        slider.setThumbImage(sliderThumbImage, for: UIControlState())
        slider.setThumbImage(sliderThumbImage, for: UIControlState.highlighted)
        
        imageView.frame = view.bounds
        videoView?.frame = CGRect(x: 0, y: view.frame.height / 6, width: view.frame.width, height: view.frame.height / 2)
        imageEffectView.frame = view.bounds
        videoEffectView.frame = view.bounds

        view.clipsToBounds = true
        view.addSubview(imageCoverView)
        imageView.addSubview(imageEffectView)
        view.addSubview(imageView)
        if let videoView = videoView {
            videoView.addSubview(videoEffectView)
            view.addSubview(videoView)
        }

        view.addSubview(titleLabel)
        view.addSubview(subTitleLabel)
        view.addSubview(currentLabel)
        view.addSubview(totalLabel)
        view.addSubview(slider)
        view.addSubview(nextButton)
        view.addSubview(playButton)
        view.addSubview(previousButton)
        view.addSubview(closeButton)
        
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        slider.addTarget(        self, action: #selector(SimplePlayerViewController.previewSeek),  for: UIControlEvents.valueChanged)
        slider.addTarget(        self, action: #selector(SimplePlayerViewController.stopSeek),     for: UIControlEvents.touchUpInside)
        slider.addTarget(        self, action: #selector(SimplePlayerViewController.cancelSeek),   for: UIControlEvents.touchUpOutside)
        nextButton.addTarget(    self, action: #selector(SimplePlayerViewController.forward),      for: UIControlEvents.touchUpInside)
        playButton.addTarget(    self, action: #selector(SimplePlayerViewController.toggle),       for: UIControlEvents.touchUpInside)
        previousButton.addTarget(self, action: #selector(SimplePlayerViewController.back),         for: UIControlEvents.touchUpInside)
        closeButton.addTarget(   self, action: #selector(SimplePlayerViewController.close),        for: UIControlEvents.touchUpInside)
        if let videoView = videoView {
            videoView.addTarget( self, action: #selector(SimplePlayerViewController.toggle),       for: UIControlEvents.touchUpInside)
        }
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(SimplePlayerViewController.sliderDragged(_:)))
        slider.addGestureRecognizer(panGesture)
    }
    
    open func updateConstraints() {
        currentLabel.snp.makeConstraints { make in
            make.left.equalTo(self.view.snp.left).offset(self.paddingSide).priority(priorityHigh)
            make.bottom.equalTo(self.slider.snp.bottom).offset(-self.paddingBottomTime)
        }
        totalLabel.snp.makeConstraints { make in
            make.right.equalTo(self.view.snp.right).offset(-self.paddingSide).priority(priorityHigh)
            make.bottom.equalTo(self.slider.snp.bottom).offset(-self.paddingBottomTime)
        }
        slider.snp.makeConstraints { make in
            make.left.equalTo(self.view.snp.left).offset(self.paddingSide)
            make.right.equalTo(self.view.snp.right).offset(-self.paddingSide)
            make.bottom.equalTo(self.view.snp.bottom).offset(-self.paddingBottom)
        }
        previousButton.snp.makeConstraints { make in
            make.left.equalTo(self.view.snp.left).offset(self.paddingSide)
            make.centerY.equalTo(self.view.snp.centerY).offset(-self.buttonSize)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        playButton.snp.makeConstraints { (make) -> () in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(self.view.snp.centerY).offset(-self.buttonSize)
            make.width.equalTo(self.buttonSize * 2)
            make.height.equalTo(self.buttonSize * 2)
        }
        nextButton.snp.makeConstraints { make in
            make.right.equalTo(self.view.snp.right).offset(-self.paddingSide)
            make.centerY.equalTo(self.view.snp.centerY).offset(-self.buttonSize)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        closeButton.snp.makeConstraints { make in
            make.left.equalTo(self.view.snp.left).offset(self.paddingSide)
            make.top.equalTo(self.view.snp.top).offset(self.paddingSide)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.slider.snp.left)
            make.bottom.equalTo(self.slider.snp.top).offset(-self.paddingTitleBottom)
            make.width.equalTo(self.view.snp.width).offset(-paddingSide*2)
        }
        subTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.slider.snp.left)
            make.bottom.equalTo(self.slider.snp.top).offset(-self.paddingSubTitleBottom)
            make.width.equalTo(self.view.snp.width).offset(-paddingSide*2)
        }
    }

    @objc func sliderDragged(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            if let targetView = sender.view {
                let point = sender.translation(in: targetView)
                state = .dragging(point, slider.value)
            }
        case .changed:
            if let targetView = sender.view {
                let point = sender.translation(in: targetView)
                switch state {
                case .normal: break
                case .dragging(let startPoint, let startValue):
                    let dx  = point.x - startPoint.x
                    let v   = startValue + Float(dx / slider.frame.width) * slider.maximumValue
                    let val = min(slider.maximumValue, max(0, v))
                    updateTime(current: val, total: slider.maximumValue);
                case .changing: break
                }
            }
        case .ended:
            if let _ = sender.view {
                let value = TimeInterval(slider.value)
                notify(.timeChanged(value))
                state = .changing(value)
            }
        case .cancelled: break
        case .failed:    break
        case .possible:  break
        }
    }
    
    open override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        self.updateConstraints()
    }
    
    open override func removeFromParentViewController() {
        super.removeFromParentViewController()
        observers = []
        videoView?.player = nil
    }
    
    open override func updateViewWithTrack(_ track: Track, animated: Bool) {
        titleLabel.text    = track.title
        subTitleLabel.text = track.subtitle
        guard let currentTrack = player.currentTrack else { return }
        let isCurrentTrack = currentTrack.streamURL == track.streamURL
        if isCurrentTrack && track.isVideo {
            videoView?.player = player.avPlayer
            imageView.sd_setImage(with: track.artworkURL as URL?? ?? track.thumbnailURL as URL!)
        } else {
            videoView?.player = nil
            imageView.sd_setImage(with: track.artworkURL as URL?? ?? track.thumbnailURL as URL!)
        }
        if !slider.isTracking {
            timeUpdated()
        }
        let action = {
            switch self.player.state {
            case .init, .load, .pause:
                self.videoEffectView.effect         = UIBlurEffect(style: .dark)
                self.imageEffectView.effect         = UIBlurEffect(style: .dark)
                self.imageCoverView.backgroundColor = UIColor.clear
                self.playButton.alpha               = 1.0
                self.nextButton.alpha               = 1.0
                self.nextButton.isEnabled             = self.player.nextTrack != nil
                self.previousButton.alpha           = 1.0
                self.previousButton.isEnabled         = self.player.previousTrack != nil
            default:
                self.videoEffectView.effect = nil
                self.imageEffectView.effect = track.isVideo ? UIBlurEffect(style: .dark) : nil
                self.imageCoverView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
                self.playButton.alpha       = 0
                self.nextButton.alpha       = 0
                self.previousButton.alpha   = 0
            }
        }
        if animated {
            UIView.animate(withDuration: toggleAnimationDuration, delay: 0, options:UIViewAnimationOptions(), animations: action, completion: { finished in
            })
        } else {
            action()
        }
    }
    
    open override func enablePlayerView() {
        guard let avPlayer = player.avPlayer else { return }
        if videoView?.player != avPlayer {
            videoView?.player = avPlayer
        }
    }
    
    open override func disablePlayerView() {
        videoView?.player = nil
    }
    
    open override func timeUpdated() {
        switch state {
        case .dragging: break
        case .normal:
            if let info = player.playingInfo {
                updateTime(current: Float(info.elapsedTime), total: Float(info.duration))
            }
        case .changing(let time):
            guard let info = player.playingInfo else { return }
            if time - info.elapsedTime < 1.0 {
                state = .normal
            }
        }
    }
    
    func updateTime(current: Float, total: Float) {
        if total > 0 {
            currentLabel.text   = TimeHelper.timeStr(current)
            totalLabel.text     = TimeHelper.timeStr(total)
            slider.value        = Float(current)
            slider.maximumValue = Float(total)
        } else {
            currentLabel.text   = "00:00"
            totalLabel.text     = "00:00"
            slider.value        = 0
            slider.maximumValue = 0
        }
    }

    @objc func toggle()   { notify(.toggle) }
    @objc func back()     { notify(.previous) }
    @objc func forward()  { notify(.next) }
    @objc func close()    { notify(.close) }
    @objc func previewSeek() {
        if slider.isTracking {
            updateTime(current: slider.value, total: slider.maximumValue)
        }
        notify(.timeChanged(TimeInterval(slider.value)))
    }
    
    @objc func stopSeek() {
        notify(.timeChanged(TimeInterval(slider.value)))
    }
    
    @objc func cancelSeek() {
        timeUpdated()
    }
}
