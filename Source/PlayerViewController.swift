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
    let controlPanelHeight: CGFloat = 130.0

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

    public var controlPanel: ControlPanel!
    public var playerView:   PlayerView!
    public var adBannerView: ADBannerView?

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
        createSubviews()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        createSubviews()
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createSubviews()
    }

    public func createSubviews() {
        controlPanel = ControlPanel()
        playerView   = PlayerView()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close",//.localize(),
                                                           style: UIBarButtonItemStyle.Done,
                                                          target: self,
                                                          action: "close")
        view.backgroundColor = UIColor.blackColor()

        playerView.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        playerView.setImage(thumbImage, forState: UIControlState.allZeros)
        controlPanel.slider.addTarget(self, action: "previewSeek", forControlEvents: UIControlEvents.ValueChanged)
        controlPanel.slider.addTarget(self, action: "stopSeek", forControlEvents: UIControlEvents.TouchUpInside)
        controlPanel.slider.addTarget(self, action: "cancelSeek", forControlEvents: UIControlEvents.TouchUpOutside)
        controlPanel.nextButton.addTarget(    self, action: "next",         forControlEvents: UIControlEvents.TouchUpInside)
        controlPanel.playButton.addTarget(    self, action: "toggle",       forControlEvents: UIControlEvents.TouchUpInside)
        controlPanel.previousButton.addTarget(self, action: "previous",     forControlEvents: UIControlEvents.TouchUpInside)
        playerView.addTarget(    self, action: "toggleScreen", forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(playerView)
        view.addSubview(controlPanel)
        resizeViews(0.0)

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
        if controlPanel.slider.tracking {
            CMTimeMakeWithSeconds(Float64(controlPanel.slider.value), 1)
            updateViewsOfTime(current: controlPanel.slider.value, total: controlPanel.slider.maximumValue)
        }
        if let state = player?.currentState {
            if state == .Pause {
                player?.seekToTime(CMTimeMakeWithSeconds(Float64(controlPanel.slider.value), 1))
            }
        }
    }

    func stopSeek() {
        if let _player = player {
            _player.seekToTime(CMTimeMakeWithSeconds(Float64(controlPanel.slider.value), 1))
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
                controlPanel.playButton.setImage(UIImage(named: "pause", inBundle: bundle, compatibleWithTraitCollection: nil), forState: UIControlState.allZeros)
            } else {
                controlPanel.playButton.setImage(UIImage(named: "play", inBundle: bundle, compatibleWithTraitCollection: nil), forState: UIControlState.allZeros)
            }
        }
        if let track = player?.currentTrack {
            controlPanel.titleLabel.text = track.title
            if track.isVideo {
                playerView.setImage(nil, forState: UIControlState.allZeros)
            } else if let url = track.thumbnailUrl {
                playerView.sd_setImageWithURL(url, forState: UIControlState.allZeros)
            } else {
                playerView.setImage(thumbImage, forState: UIControlState.allZeros)
            }
        } else {
            controlPanel.totalLabel.text   = "00:00"
            controlPanel.currentLabel.text = "00:00"
            playerView.setImage(thumbImage, forState: UIControlState.allZeros)
        }
        if let (current, total) = player?.secondPair {
            if !controlPanel.slider.tracking { updateViewsOfTime(current: Float(current), total: Float(total)) }
        }
    }

    func updateViewsOfTime(#current: Float, total: Float) {
        if total > 0 {
            controlPanel.currentLabel.text   = TimeHelper.timeStr(current)
            controlPanel.totalLabel.text     = TimeHelper.timeStr(total)
            controlPanel.slider.value        = Float(current)
            controlPanel.slider.maximumValue = Float(total)
        } else {
            controlPanel.currentLabel.text   = "00:00"
            controlPanel.totalLabel.text     = "00:00"
            controlPanel.slider.value        = 0
            controlPanel.slider.maximumValue = 0
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
