//
//  PlayerViewController.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 3/1/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import iAd
import AVFoundation
import SnapKit
import WebImage

public class PlayerViewController: UIViewController, DraggableCoverViewControllerDelegate, ADBannerViewDelegate {
    public let minThumbnailWidth:  CGFloat = 75.0
    public let minThumbnailHeight: CGFloat = 60.0

    class ModalPlayerObserver: PlayerObserver {
        let vc: PlayerViewController
        init(playerViewController: PlayerViewController) {
            vc = playerViewController
            super.init()
        }
        override func timeUpdated()               { vc.updateViews() }
        override func didPlayToEndTime()          { vc.updateViews() }
        override func statusChanged()             { vc.updateViews() }
        override func trackSelected(track: Track, index: Int, playlist: Playlist) {
            vc.updateViews()
        }
        override func trackUnselected(track: Track, index: Int, playlist: Playlist) {
            vc.updateViews()
        }
    }

    let paddingSide:        CGFloat = 10.0
    let paddingBottom:      CGFloat = 15.0
    let paddingBottomTime:  CGFloat = 5.0
    let controlPanelHeight: CGFloat = 130.0
    let buttonSize:         CGFloat = 40.0
    let buttonPadding:      CGFloat = 30.0

    public var controlPanel:        UIView!
    public var slider:              UISlider!
    public var previousButton:      UIButton!
    public var playButton:          UIButton!
    public var nextButton:          UIButton!
    public var titleLabel:          UILabel!
    public var currentLabel:        UILabel!
    public var totalLabel:          UILabel!
    public var playerView:          PlayerView!
    public var adBannerView:        ADBannerView?

    var modalPlayerObserver:  ModalPlayerObserver!
    public var player:        Player<PlayerObserver>?
    public var thumbnailView: UIView { get { return playerView }}

    public var draggableCoverViewController: DraggableCoverViewController?
    public var thumbImage: UIImage {
        let bundle = NSBundle(identifier: "io.kumabook.PlayerKit")
        return UIImage(named: "thumb", inBundle: bundle, compatibleWithTraitCollection: nil)!
    }

    public init(player: Player<PlayerObserver>) {
        super.init(nibName: nil, bundle: nil)
        self.player         = player
        modalPlayerObserver = ModalPlayerObserver(playerViewController: self)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close",//.localize(),
                                                           style: UIBarButtonItemStyle.Done,
                                                          target: self,
                                                          action: "close")
        view.backgroundColor   = UIColor.blackColor()
        controlPanel           = UIView()
        titleLabel             = UILabel()
        currentLabel           = UILabel()
        totalLabel             = UILabel()
        slider                 = UISlider()
        nextButton             = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        playButton             = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        previousButton         = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        playerView             = PlayerView()

        titleLabel.textColor     = UIColor.whiteColor()
        titleLabel.font          = UIFont.boldSystemFontOfSize(16)
        titleLabel.textColor     = UIColor.whiteColor()
        titleLabel.textAlignment = NSTextAlignment.Center
        currentLabel.textColor   = UIColor.whiteColor()
        currentLabel.font        = UIFont.boldSystemFontOfSize(15)
        totalLabel.textColor     = UIColor.whiteColor()
        totalLabel.font          = UIFont.boldSystemFontOfSize(15)

        nextButton.tintColor     = UIColor.whiteColor()
        playButton.tintColor     = UIColor.whiteColor()
        previousButton.tintColor = UIColor.whiteColor()

        playerView.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        playerView.setImage(thumbImage, forState: UIControlState.allZeros)
        slider.addTarget(self, action: "previewSeek", forControlEvents: UIControlEvents.ValueChanged)
        slider.addTarget(self, action: "stopSeek", forControlEvents: UIControlEvents.TouchUpInside)
        slider.addTarget(self, action: "cancelSeek", forControlEvents: UIControlEvents.TouchUpOutside)
        let bundle = NSBundle(identifier: "io.kumabook.PlayerKit")
        let nextImage     = UIImage(named:     "next", inBundle: bundle, compatibleWithTraitCollection: nil)
        let playImage     = UIImage(named:     "next", inBundle: bundle, compatibleWithTraitCollection: nil)
        let previousImage = UIImage(named: "previous", inBundle: bundle, compatibleWithTraitCollection: nil)
        nextButton.setImage(        nextImage, forState: UIControlState.allZeros)
        playButton.setImage(        playImage, forState: UIControlState.allZeros)
        previousButton.setImage(previousImage, forState: UIControlState.allZeros)
        nextButton.addTarget(    self, action: "next",         forControlEvents: UIControlEvents.TouchUpInside)
        playButton.addTarget(    self, action: "toggle",       forControlEvents: UIControlEvents.TouchUpInside)
        previousButton.addTarget(self, action: "previous",     forControlEvents: UIControlEvents.TouchUpInside)
        playerView.addTarget(    self, action: "toggleScreen", forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(playerView)
        view.addSubview(controlPanel)
        controlPanel.backgroundColor = UIColor.darkGrayColor()
        controlPanel.clipsToBounds = true
        controlPanel.addSubview(titleLabel)
        controlPanel.addSubview(currentLabel)
        controlPanel.addSubview(totalLabel)
        controlPanel.addSubview(slider)
        controlPanel.addSubview(nextButton)
        controlPanel.addSubview(playButton)
        controlPanel.addSubview(previousButton)
        resizeViews(0.0)

        currentLabel.snp_makeConstraints { make in
            make.left.equalTo(self.controlPanel.snp_left).offset(self.paddingSide).priorityHigh()
            make.top.equalTo(self.controlPanel.snp_top).offset(self.paddingBottomTime)
        }
        totalLabel.snp_makeConstraints { make in
            make.right.equalTo(self.controlPanel.snp_right).offset(-self.paddingSide).priorityHigh()
            make.top.equalTo(self.controlPanel.snp_top).offset(self.paddingBottomTime)
        }
        slider.snp_makeConstraints { make in
            make.left.equalTo(self.controlPanel.snp_left).offset(self.paddingSide)
            make.right.equalTo(self.controlPanel.snp_right).offset(-self.paddingSide)
            make.top.equalTo(self.currentLabel.snp_bottom).offset(self.paddingBottom)
        }
        previousButton.snp_makeConstraints { make in
            make.right.equalTo(self.playButton.snp_left).offset(-self.buttonPadding)
            make.centerY.equalTo(self.playButton.snp_centerY)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        playButton.snp_makeConstraints { (make) -> () in
            make.centerX.equalTo(self.controlPanel.snp_centerX)
            make.top.equalTo(self.slider.snp_bottom).offset(self.paddingBottom)
            make.width.equalTo(self.buttonSize * 3/5)
            make.height.equalTo(self.buttonSize * 3/5)
        }
        nextButton.snp_makeConstraints { make in
            make.left.equalTo(self.playButton.snp_right).offset(self.buttonPadding)
            make.centerY.equalTo(self.playButton.snp_centerY)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        titleLabel.snp_makeConstraints { make in
            make.left.greaterThanOrEqualTo(self.controlPanel.snp_left).offset(self.paddingSide*6)
            make.right.greaterThanOrEqualTo(self.controlPanel.snp_right).offset(-self.paddingSide*6)
            make.centerX.equalTo(self.controlPanel.snp_centerX)
            make.top.equalTo(self.controlPanel.snp_top).offset(self.paddingBottomTime)
            make.bottom.equalTo(self.slider.snp_top).offset(self.paddingBottomTime)
        }
        updateViews()
        player?.addObserver(modalPlayerObserver)
        enablePlayerView()
        controlPanel.addGestureRecognizer(UIPanGestureRecognizer())
    }

    public func disablePlayerView() {
        playerView.player = nil
    }

    public func enablePlayerView() {
        if let avPlayer = player?.avPlayer {
            if playerView.player != avPlayer {
                playerView.player = avPlayer
            }
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    public func toggle() {
        player?.toggle()
    }

    public func next() {
        player?.next()
    }

    public func previous() {
        player?.previous()
    }

    public func didMinimizedCoverView() {
        updateViews()
        removeAdView()
    }

    public func didMaximizedCoverView() {
        updateViews()
        addAdView()
        showAdView()
    }

    public func didResizeCoverView(rate: CGFloat) {
        resizeViews(rate)
    }

    public func resizeViews(rate: CGFloat) {
        let  f = view.frame
        var ch = controlPanelHeight * rate
        var  h = f.height - ch
        if let pf = draggableCoverViewController?.view.frame {
            playerView.frame     = CGRect(x: 0, y: 0, width:  f.width, height: h)
            controlPanel.frame   = CGRect(x: 0, y: h, width: pf.width, height: ch)
            view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: rate)
            controlPanel.alpha   = rate
        }
        hideAdView()
    }

    public func toggleScreen() {
        draggableCoverViewController?.toggleScreen()
    }

    func previewSeek() {
        if slider.tracking {
            CMTimeMakeWithSeconds(Float64(slider.value), 1)
            updateViewsOfTime(current: slider.value, total: slider.maximumValue)
        }
        if let state = player?.currentState {
            if state == .Pause {
                player?.seekToTime(CMTimeMakeWithSeconds(Float64(slider.value), 1))
            }
        }
    }

    func stopSeek() {
        if let _player = player {
            _player.seekToTime(CMTimeMakeWithSeconds(Float64(slider.value), 1))
        }
    }

    func cancelSeek() {
        if let _player = player {
            updateViews()
        }
    }

    func updateViews() {
        let bundle = NSBundle(identifier: "io.kumabook.PlayerKit")
        enablePlayerView()
        if let state = player?.currentState {
            if state.isPlaying {
                playButton.setImage(UIImage(named: "pause", inBundle: bundle, compatibleWithTraitCollection: nil), forState: UIControlState.allZeros)
            } else {
                playButton.setImage(UIImage(named: "play", inBundle: bundle, compatibleWithTraitCollection: nil), forState: UIControlState.allZeros)
            }
        }
        if let track = player?.currentTrack {
            titleLabel.text = track.title
            if let url = track.thumbnailUrl {
                playerView.sd_setImageWithURL(url, forState: UIControlState.allZeros)
            } else {
                playerView.setImage(thumbImage, forState: UIControlState.allZeros)
            }
        } else {
            totalLabel.text   = "00:00"
            currentLabel.text = "00:00"
            playerView.setImage(thumbImage, forState: UIControlState.allZeros)
        }
        if let (current, total) = player?.secondPair {
            if !slider.tracking { updateViewsOfTime(current: Float(current), total: Float(total)) }
        }
    }

    func updateViewsOfTime(#current: Float, total: Float) {
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

    public func close() {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func addAdView() {
        if adBannerView == nil {
            let adView = ADBannerView()
            adView.delegate = self
            adView.alpha = 0.0
            view.addSubview(adView)
            adView.snp_makeConstraints { make in
                make.left.equalTo(self.view.snp_left)
                make.right.equalTo(self.view.snp_right)
                make.top.equalTo(self.view.snp_top)
            }
            adBannerView = adView
        }
    }

    func removeAdView() {
        if let adView = adBannerView {
            adView.delegate = nil
            adView.removeFromSuperview()
            adBannerView = nil
        }
    }

    public func showAdView() { if let adView = adBannerView { adView.hidden = false } }
    public func hideAdView() { if let adView = adBannerView { adView.hidden = true } }

    // MARK: - ADBannerViewDelegate

    public func bannerViewDidLoadAd(banner: ADBannerView!) {
        adBannerView?.alpha = 1.0
    }

    public func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        removeAdView()
    }
}
