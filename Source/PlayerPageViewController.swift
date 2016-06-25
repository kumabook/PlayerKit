//
//  PlayerPageViewController.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 3/1/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit
import WebImage

extension UIScrollView {
    var currentPage: Int {
        return Int((contentOffset.x + (0.5 * frame.size.width)) / frame.width)
    }
}

class PlayerPageViewPlayerObserver: PlayerObserver {
    var vc: PlayerPageViewControllerType?
    init(playerViewController: PlayerPageViewControllerType) {
        vc = playerViewController
        super.init()
    }
    override func listen(event: Event) {
        switch event {
        case .TimeUpdated:               vc?.timeUpdated()
        case .DidPlayToEndTime:          vc?.updateViews(false)
        case .StatusChanged:             vc?.updateViews(true)
        case .TrackSelected(_, _, _):    vc?.updatePlayerViews()
        case .TrackUnselected(_, _, _):  vc?.updateViews(false)
        case .ErrorOccured:              vc?.updateViews(false)
        case .NextPlaylistRequested:     vc?.updateViews(false)
        case .PreviousPlaylistRequested: vc?.updateViews(false)
        case .PlaylistChanged: break
        }
    }
}

class PlayerPageViewPlayerViewObserver: PlayerViewObserver {
    var vc: PlayerPageViewControllerType?
    init(playerViewController: PlayerPageViewControllerType) {
        vc = playerViewController
        super.init()
    }
    override func listen(event: Event) {
        switch event {
        case .Close:                 vc?.close()
        case .Next:                  vc?.next()
        case .Previous:              vc?.previous()
        case .Toggle:                vc?.toggle()
        case .TimeChanged(let time): vc?.changeTime(time)
        case .Message(let message):  vc?.onMessage(message)
        }
    }
}

protocol PlayerPageViewControllerType {
    func timeUpdated()
    func updateViews(animated: Bool)
    func updatePlayerViews()

    func close()
    func next()
    func previous()
    func toggle()
    func changeTime(time: CMTime)
    func onMessage(message: String)
}

public class PlayerPageViewController<PVC: PlayerViewController, MV: MiniPlayerView>: UIViewController, DraggableCoverViewControllerDelegate, UIScrollViewDelegate, PlayerPageViewControllerType, MiniPlayerViewDelegate {
    public var minThumbnailWidth:  CGFloat { return self.view.frame.width }
    public var minThumbnailHeight: CGFloat { return 60.0 }
    public var thumbWidth:         CGFloat = 75.0
    let controlPanelHeight:        CGFloat = 130.0
    public var playerViews:        [PlayerViewController] = []

    public var scrollView:     UIScrollView!
    public var miniPlayerView: MV!

    public var imageView:      UIImageView!
    public var videoView:      VideoView!

    var modalPlayerObserver:     PlayerPageViewPlayerObserver!
    var modalPlayerViewObserver: PlayerPageViewPlayerViewObserver!
    public var player: Player!

    public var draggableCoverViewController: DraggableCoverViewController?
    public var thumbImage: UIImage {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let color = UIColor.init(red: 212, green: 212, blue: 212, alpha: 0.2)
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(100, 100), false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return image

    }

    public init(player: Player) {
        super.init(nibName: nil, bundle: nil)
        self.player             = player
        self.playerViews        = []
        modalPlayerObserver     = PlayerPageViewPlayerObserver(playerViewController: self)
        modalPlayerViewObserver = PlayerPageViewPlayerViewObserver(playerViewController: self)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close",//.localize(),
                                                           style: UIBarButtonItemStyle.Done,
                                                          target: self,
                                                          action: #selector(PlayerPageViewController.close))
        view.backgroundColor = UIColor.blackColor()
        let w = view.frame.width
        let h = view.frame.height
        miniPlayerView       = MV(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: minThumbnailHeight))
        imageView            = UIImageView()
        imageView.frame      = CGRect(x: 0, y: 0,  width:  thumbWidth, height: minThumbnailHeight)
        videoView            = VideoView()
        videoView.frame      = CGRect(x: 0, y: 0,  width:  thumbWidth, height: minThumbnailHeight)
        view.addSubview(miniPlayerView)
        miniPlayerView.addSubview(imageView)
        miniPlayerView.addSubview(videoView)
        scrollView = UIScrollView(frame: CGRect(x: 0, y: minThumbnailHeight, width: w, height: h))
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        view.addSubview(scrollView)
        resizeViews(0.0)
        updateViews()
        player?.addObserver(modalPlayerObserver)
        miniPlayerView.delegate = self
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    public var currentPlayerView: PVC? {
        if let _  = player?.previousTrack {
            return playerViews[1] as! PVC
        } else if playerViews.count > 0 {
            return playerViews[0] as! PVC
        }
        return nil
    }
    public var previousPlayerView: PVC? {
        if let _  = player?.previousTrack {
            return playerViews.count > 0 ? playerViews[0] as! PVC : nil
        }
        return nil
    }
    public var nextPlayerView: PVC? {
        if let _  = player?.nextTrack {
            if let _  = player?.previousTrack {
                return playerViews.count > 2 ? playerViews[2] as! PVC : nil
            } else {
                return playerViews.count > 1 ? playerViews[1] as! PVC : nil
            }
        }
        return nil
    }
    
    public func updatePlayerViews() {
        for i in 0..<playerViews.count {
            playerViews[i].removeObserver(self.modalPlayerViewObserver)
            playerViews[i].willMoveToParentViewController(nil)
            playerViews[i].view.removeFromSuperview()
            playerViews[i].removeFromParentViewController()
        }
        playerViews = []
        let w = scrollView.frame.width
        let h = scrollView.frame.height
        let tracks = [player?.previousTrack, player?.currentTrack, player?.nextTrack].filter { $0 != nil}.map { $0! }
        tracks.enumerate().forEach { i, track in
            var pvc: PlayerViewController = PVC(player: player)
            self.addChildViewController(pvc)
            pvc.view.frame = CGRect(x:  w * CGFloat(i), y: 0, width: w, height: h)
            pvc.updateViewWithTrack(track, animated: false)
            pvc.addObserver(self.modalPlayerViewObserver)
            scrollView.addSubview(pvc.view)
            pvc.didMoveToParentViewController(self)
            playerViews.append(pvc)
        }
        scrollView.contentSize = CGSize(width: CGFloat(tracks.count) * w, height: h)
        scrollView.showsHorizontalScrollIndicator = false

        if let _  = player?.previousTrack {
            scrollView.scrollRectToVisible(CGRect(x: w, y: 0, width: w, height: h), animated: false)
        } else {
            scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: w, height: h), animated: false)
        }
    }

    public func close() {
        draggableCoverViewController?.toggleScreen()
    }

    public func toggle() {
        player?.toggle()
    }

    public func next() {
        let w = scrollView.frame.width
        let h = scrollView.frame.height
        if let _  = player?.previousTrack {
            scrollView.scrollRectToVisible(CGRect(x: 2 * w, y: 0, width: w, height: h), animated: true)
        } else {
            scrollView.scrollRectToVisible(CGRect(x:     w, y: 0, width: w, height: h), animated: true)
        }
    }

    public func previous() {
        let w = scrollView.frame.width
        let h = scrollView.frame.height
        scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: w, height: h), animated: true)
    }
    
    public var thumbnailView: UIView {
        return imageView
    }

    public func didMinimizedCoverView() {
        updateViews()
    }

    public func didMaximizedCoverView() {
        updateViews()
    }

    public func didResizeCoverView(rate: CGFloat) {
        resizeViews(rate)
    }

    public func resizeViews(rate: CGFloat) {
    }

    public func timeUpdated() {
        guard let view   = currentPlayerView else { return }
        view.timeUpdated()
    }
    
    public func updateViews(animated: Bool = false) {
        guard let track = player?.currentTrack else {
            imageView.image  = self.thumbImage
            videoView.player = nil
            return
        }
        currentPlayerView?.updateViewWithTrack(track, animated: animated)
        miniPlayerView.updateViewWithPlayer(player)
        if let previousTrack = player.previousTrack {
            previousPlayerView?.updateViewWithTrack(previousTrack, animated: false)
        }
        if let nextTrack = player.nextTrack {
            nextPlayerView?.updateViewWithTrack(nextTrack, animated: false)
        }
        if track.isVideo {
            let state = player.currentState
            if state == .Play || state == .Pause {
                videoView.player = player.avPlayer
                imageView.image = nil
                return
            }
        }
        if let url = track.thumbnailUrl {
            videoView.player = nil
            imageView.sd_setImageWithURL(url)
        } else {
            videoView.player = nil
            imageView.image  = thumbImage
        }
    }

    public func changeTime(time: CMTime) {
        player?.seekToTime(time)
    }

    public func onMessage(message: String) {
    }
    
    public func enablePlayerView() {
        currentPlayerView?.enablePlayerView()
    }
    public func disablePlayerView() {
        currentPlayerView?.disablePlayerView()
    }

    private func didScrollEnd() {
        let dst = scrollView.currentPage
        let current = player?.previousTrack == nil ? 0 : 1
        if dst < current {
            player?.previous()
        } else if dst > current {
            player?.next()
        }
    }
    
    // MARK: UIScrollViewDelegate

    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        didScrollEnd()
    }

    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        didScrollEnd()
    }

    // MARK: - MiniPlayerViewDelegate -

    public func miniPlayerViewPlayButtonTouched() {
        player?.toggle()
    }

    public func miniPlayerViewPreviousButtonTouched() {
        player?.previous()
    }

    public func miniPlayerViewNextButtonTouched() {
        player?.next()
    }

    public func miniPlayerViewUpdate() {
        updateViews()
    }
}
