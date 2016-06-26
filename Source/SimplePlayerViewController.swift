//
//  SimplePlayerViewController.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/24/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import AVFoundation
import UIKit

public class SimplePlayerViewController: PlayerViewController {
    
    let paddingSide:           CGFloat = 10.0
    let paddingBottom:         CGFloat = 45.0
    let paddingTitleBottom:    CGFloat = 64.0
    let paddingSubTitleBottom: CGFloat = 40.0
    let paddingBottomTime:     CGFloat = 40.0
    let buttonSize:            CGFloat = 40.0
    let buttonPadding:         CGFloat = 30.0
    var toggleAnimationDuration: Double = 0.25
    
    public var videoView:           VideoView!
    public var imageView:           UIImageView!
    
    public var slider:              UISlider!
    public var previousButton:      UIButton!
    public var playButton:          UIButton!
    public var nextButton:          UIButton!
    public var closeButton:         UIButton!
    public var iconImage:           UIImage!
    public var titleLabel:          UILabel!
    public var subTitleLabel:       UILabel!
    public var currentLabel:        UILabel!
    public var totalLabel:          UILabel!
    public var imageEffectView:     UIVisualEffectView!
    public var imageCoverView:      UIView!
    public var videoEffectView:     UIVisualEffectView!
    
    public required init(player: Player) {
        super.init(player: player)
        initializeSubviews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeSubviews()
    }
    
    public func initializeSubviews() {
        titleLabel     = UILabel()
        subTitleLabel  = UILabel()
        currentLabel   = UILabel()
        totalLabel     = UILabel()
        slider         = UISlider()
        nextButton     = UIButton(type: UIButtonType.System)
        playButton     = UIButton(type: UIButtonType.System)
        previousButton = UIButton(type: UIButtonType.System)
        
        closeButton    = UIButton(type: UIButtonType.System)
        
        titleLabel.text             = "title title"
        titleLabel.textAlignment    = NSTextAlignment.Left
        subTitleLabel.text          = "subtitle subtitle"
        subTitleLabel.textAlignment = NSTextAlignment.Left
        currentLabel.text           = "00:00"
        totalLabel.text             = "00:00"
        
        imageView  = UIImageView()
        videoView  = VideoView()
        imageEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        imageCoverView  = UIView()
        videoEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        
        titleLabel.textColor        = UIColor.whiteColor()
        titleLabel.font             = UIFont.boldSystemFontOfSize(16)
        titleLabel.textColor        = UIColor.whiteColor()
        titleLabel.textAlignment    = NSTextAlignment.Left
        subTitleLabel.textColor     = UIColor.whiteColor()
        subTitleLabel.textAlignment = NSTextAlignment.Left
        currentLabel.textColor      = UIColor.whiteColor()
        currentLabel.font           = UIFont.boldSystemFontOfSize(15)
        totalLabel.textColor        = UIColor.whiteColor()
        totalLabel.font             = UIFont.boldSystemFontOfSize(15)
        
        nextButton.tintColor        = UIColor.whiteColor()
        playButton.tintColor        = UIColor.whiteColor()
        previousButton.tintColor    = UIColor.whiteColor()
        
        closeButton.tintColor       = UIColor.whiteColor()
        
        let bundle = NSBundle(identifier: "io.kumabook.PlayerKit")
        let nextImage     = UIImage(named:     "next", inBundle: bundle, compatibleWithTraitCollection: nil)
        let playImage     = UIImage(named:     "play", inBundle: bundle, compatibleWithTraitCollection: nil)
        let previousImage = UIImage(named: "previous", inBundle: bundle, compatibleWithTraitCollection: nil)
        let closeImage    = UIImage(named:    "close", inBundle: bundle, compatibleWithTraitCollection: nil)
        nextButton.setImage(        nextImage, forState: UIControlState())
        playButton.setImage(        playImage, forState: UIControlState())
        previousButton.setImage(previousImage, forState: UIControlState())
        closeButton.setImage(closeImage, forState: UIControlState())
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(100, 100), false, 0.0)
        let blank: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        slider.setThumbImage(blank, forState: UIControlState.Normal)
        slider.setThumbImage(blank, forState: UIControlState.Highlighted)
        
        imageView.frame = view.bounds
        videoView.frame = CGRect(x: 0, y: 50, width: view.frame.width, height: view.frame.height / 2)
        imageEffectView.frame = view.bounds
        videoEffectView.frame = view.bounds
        
        
        view.clipsToBounds = true
        view.addSubview(imageEffectView)
        view.addSubview(imageCoverView)
        imageEffectView.insertSubview(imageView, atIndex: 0)
        view.addSubview(videoEffectView)
        videoEffectView.insertSubview(videoView, atIndex: 0)
        
        view.addSubview(titleLabel)
        view.addSubview(subTitleLabel)
        view.addSubview(currentLabel)
        view.addSubview(totalLabel)
        view.addSubview(slider)
        view.addSubview(nextButton)
        view.addSubview(playButton)
        view.addSubview(previousButton)
        view.addSubview(closeButton)
        
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        slider.addTarget(        self, action: #selector(SimplePlayerViewController.previewSeek),  forControlEvents: UIControlEvents.ValueChanged)
        slider.addTarget(        self, action: #selector(SimplePlayerViewController.stopSeek),     forControlEvents: UIControlEvents.TouchUpInside)
        slider.addTarget(        self, action: #selector(SimplePlayerViewController.cancelSeek),   forControlEvents: UIControlEvents.TouchUpOutside)
        nextButton.addTarget(    self, action: #selector(SimplePlayerViewController.next),         forControlEvents: UIControlEvents.TouchUpInside)
        playButton.addTarget(    self, action: #selector(SimplePlayerViewController.toggle),       forControlEvents: UIControlEvents.TouchUpInside)
        previousButton.addTarget(self, action: #selector(SimplePlayerViewController.previous),     forControlEvents: UIControlEvents.TouchUpInside)
        closeButton.addTarget(   self, action: #selector(SimplePlayerViewController.close),        forControlEvents: UIControlEvents.TouchUpInside)
        videoView.addTarget(     self, action: #selector(SimplePlayerViewController.toggle),       forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    public func updateConstraints() {
        currentLabel.snp_makeConstraints { make in
            make.left.equalTo(self.view.snp_left).offset(self.paddingSide).priorityHigh()
            make.bottom.equalTo(self.slider.snp_top).offset(self.paddingBottomTime)
        }
        totalLabel.snp_makeConstraints { make in
            make.right.equalTo(self.view.snp_right).offset(-self.paddingSide).priorityHigh()
            make.bottom.equalTo(self.slider.snp_top).offset(self.paddingBottomTime)
        }
        slider.snp_makeConstraints { make in
            make.left.equalTo(self.view.snp_left).offset(self.paddingSide)
            make.right.equalTo(self.view.snp_right).offset(-self.paddingSide)
            make.bottom.equalTo(self.view.snp_bottom).offset(-self.paddingBottom)
        }
        previousButton.snp_makeConstraints { make in
            make.left.equalTo(self.view.snp_left).offset(self.paddingSide)
            make.centerY.equalTo(self.view.snp_centerY).offset(-self.buttonSize)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        playButton.snp_makeConstraints { (make) -> () in
            make.centerX.equalTo(self.view.snp_centerX)
            make.centerY.equalTo(self.view.snp_centerY).offset(-self.buttonSize)
            make.width.equalTo(self.buttonSize * 2)
            make.height.equalTo(self.buttonSize * 2)
        }
        nextButton.snp_makeConstraints { make in
            make.right.equalTo(self.view.snp_right).offset(-self.paddingSide)
            make.centerY.equalTo(self.view.snp_centerY).offset(-self.buttonSize)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        closeButton.snp_makeConstraints { make in
            make.left.equalTo(self.view.snp_left).offset(self.paddingSide)
            make.top.equalTo(self.view.snp_top).offset(self.paddingSide)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(self.slider.snp_left)
            make.bottom.equalTo(self.slider.snp_top).offset(-self.paddingTitleBottom)
            make.width.equalTo(self.view.snp_width).offset(-paddingSide*2)
        }
        subTitleLabel.snp_makeConstraints { make in
            make.left.equalTo(self.slider.snp_left)
            make.bottom.equalTo(self.slider.snp_top).offset(-self.paddingSubTitleBottom)
            make.width.equalTo(self.view.snp_width).offset(-paddingSide*2)
        }
    }
    
    public override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        self.updateConstraints()
    }
    
    public override func removeFromParentViewController() {
        super.removeFromParentViewController()
        observers = []
        videoView.player = nil
    }
    
    public override func updateViewWithTrack(track: Track, animated: Bool) {
        titleLabel.text    = track.title
        subTitleLabel.text = track.subtitle
        guard let currentTrack = player.currentTrack else { return }
        let isCurrentTrack = currentTrack.streamUrl == track.streamUrl
        if isCurrentTrack && track.isVideo {
            videoView.player = player.avPlayer
            imageView.sd_setImageWithURL(track.thumbnailUrl)
        } else if let url = track.thumbnailUrl {
            videoView.player = nil
            imageView.sd_setImageWithURL(url)
        } else {
            videoView.player = nil
            imageView.image = nil
        }
        if !slider.tracking {
            timeUpdated()
        }
        let action = {
            switch self.player.currentState {
            case .Pause:
                self.videoEffectView.effect = UIBlurEffect(style: .Dark)
                self.imageEffectView.effect = UIBlurEffect(style: .Dark)
                self.imageCoverView.backgroundColor = UIColor.clearColor()
                self.playButton.alpha       = 1.0
                self.nextButton.alpha       = 1.0
                self.previousButton.alpha   = 1.0
            default:
                self.videoEffectView.effect = nil
                self.imageEffectView.effect = track.isVideo ? UIBlurEffect(style: .Dark) : nil
                self.imageCoverView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
                self.playButton.alpha       = 0
                self.nextButton.alpha       = 0
                self.previousButton.alpha   = 0
            }
        }
        if animated {
            UIView.animateWithDuration(toggleAnimationDuration, delay: 0, options:.CurveEaseInOut, animations: action, completion: { finished in
            })
        } else {
            action()
        }
    }
    
    public override func enablePlayerView() {
        guard let avPlayer = player.avPlayer else { return }
        if videoView.player != avPlayer {
            videoView.player = avPlayer
        }
    }
    
    public override func disablePlayerView() {
        videoView.player = nil
    }
    
    public override func timeUpdated() {
        if let (current, total) = player.secondPair {
            updateTime(current: Float(current), total: Float(total))
        }
    }
    
    func updateTime(current current: Float, total: Float) {
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
    
    func toggle()   { notify(.Toggle) }
    func previous() { notify(.Previous) }
    func next()     { notify(.Next) }
    func close()    { notify(.Close) }
    func previewSeek() {
        if slider.tracking {
            CMTimeMakeWithSeconds(Float64(slider.value), 1)
            updateTime(current: slider.value, total: slider.maximumValue)
        }
        notify(.TimeChanged(CMTimeMakeWithSeconds(Float64(slider.value), 1)))
    }
    
    func stopSeek() {
        notify(.TimeChanged(CMTimeMakeWithSeconds(Float64(slider.value), 1)))
    }
    
    func cancelSeek() {
        timeUpdated()
    }
}
