//
//  PlayerPageViewController.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 3/1/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit

internal extension UIScrollView {
    var currentPage: Int {
        return Int((contentOffset.x + (0.5 * frame.size.width)) / frame.width)
    }
}

class PlayerPageViewPlayerObserver: QueuePlayerObserver {
    var vc: PlayerPageViewControllerType?
    init(playerViewController: PlayerPageViewControllerType) {
        vc = playerViewController
        super.init()
    }
    override func listen(_ event: Event) {
        switch event {
        case .timeUpdated:               vc?.timeUpdated()
        case .didPlayToEndTime:          vc?.updateViews(false)
        case .statusChanged:             vc?.updateViews(true)
        case .trackSelected(_, _, _):    vc?.updatePlayerViews(); vc?.updateViews(false)
        case .trackUnselected(_, _, _):  vc?.updateViews(false)
        case .errorOccured:              vc?.updateViews(false)
        case .nextPlaylistRequested:     vc?.updateViews(false)
        case .previousPlaylistRequested: vc?.updateViews(false)
        case .nextTrackAdded:            vc?.updatePlayerViews(); vc?.updateViews(false)
        case .playlistChanged: break
        }
    }
}

class PlayerPageViewPlayerViewObserver: PlayerViewObserver {
    var vc: PlayerPageViewControllerType?
    init(playerViewController: PlayerPageViewControllerType) {
        vc = playerViewController
        super.init()
    }
    override func listen(_ event: Event) {
        switch event {
        case .close:                 vc?.close()
        case .next:                  vc?.next()
        case .previous:              vc?.previous()
        case .toggle:                vc?.toggle()
        case .timeChanged(let time): vc?.changeTime(time)
        case .message(let message):  vc?.onMessage(message)
        }
    }
}

protocol PlayerPageViewControllerType {
    func timeUpdated()
    func updateViews(_ animated: Bool)
    func updatePlayerViews()

    func close()
    func next()
    func previous()
    func toggle()
    func changeTime(_ time: TimeInterval)
    func onMessage(_ message: String)
}

open class PlayerPageViewController<PVC: PlayerViewController, MV: MiniPlayerView>: UIViewController, CeilingViewController, UIScrollViewDelegate, PlayerPageViewControllerType, MiniPlayerViewDelegate {

    open var coverViewController: CoverViewControllerType?

    open var minThumbnailWidth:  CGFloat { return self.view.frame.width }
    open var minThumbnailHeight: CGFloat { return 60.0 }
    open var tabHeight:          CGFloat { return minThumbnailHeight }
    open var thumbWidth:         CGFloat = 75.0
    let controlPanelHeight:      CGFloat = 130.0
    open var playerViews:        [PlayerViewController] = []

    open var scrollView:     UIScrollView!
    open var miniPlayerView: MV!

    open var imageView:      UIImageView!
    open var videoView:      VideoView!

    var playerObserver:      PlayerPageViewPlayerObserver!
    var playerViewObserver:  PlayerPageViewPlayerViewObserver!
    open var player:         QueuePlayer!

    open var videoBackgroundImage: UIImage {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let color = UIColor.init(red: 212, green: 212, blue: 212, alpha: 0.2)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 100, height: 100), false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return image!
    }

    open var defaultThumbImage: UIImage {
        return videoBackgroundImage
    }

    public init(player: QueuePlayer) {
        super.init(nibName: nil, bundle: nil)
        self.player             = player
        self.playerViews        = []
        playerObserver      = PlayerPageViewPlayerObserver(playerViewController: self)
        playerViewObserver  = PlayerPageViewPlayerViewObserver(playerViewController: self)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close",
                                                           style: UIBarButtonItemStyle.done,
                                                          target: self,
                                                          action: #selector(PlayerPageViewController.close))
        view.backgroundColor = UIColor.black
        let w = view.frame.width
        let h = view.frame.height
        miniPlayerView       = MV(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: minThumbnailHeight))
        imageView            = UIImageView()
        imageView.frame      = CGRect(x: 0, y: 0,  width:  thumbWidth, height: minThumbnailHeight)
        videoView            = VideoView()
        videoView.frame      = CGRect(x: 0, y: 0,  width:  thumbWidth, height: minThumbnailHeight)
        videoView.playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.addSubview(miniPlayerView)
        videoView.isUserInteractionEnabled = false
        imageView.isUserInteractionEnabled = false
        imageView.contentMode = .scaleAspectFill
        miniPlayerView.addSubview(imageView)
        miniPlayerView.addSubview(videoView)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(PlayerPageViewController.close))
        miniPlayerView.addGestureRecognizer(tapRecognizer)
        scrollView = UIScrollView(frame: CGRect(x: 0, y: minThumbnailHeight, width: w, height: h))
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        view.addSubview(scrollView)
        updateViewWithRate(0.0)
        updatePlayerViews()
        updateViews()
        player?.addObserver(playerObserver)
        miniPlayerView.delegate = self
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    open var currentPlayerView: PVC? {
        if let _  = player?.previousTrack {
            return playerViews.get(1) as? PVC
        } else if playerViews.count > 0 {
            return playerViews[0] as? PVC
        }
        return nil
    }
    open var previousPlayerView: PVC? {
        if let _  = player?.previousTrack {
            return playerViews.count > 0 ? playerViews[0] as? PVC : nil
        }
        return nil
    }
    open var nextPlayerView: PVC? {
        if let _  = player?.nextTrack {
            if let _  = player?.previousTrack {
                return playerViews.count > 2 ? playerViews[2] as? PVC : nil
            } else {
                return playerViews.count > 1 ? playerViews[1] as? PVC : nil
            }
        }
        return nil
    }
    
    open func updatePlayerViews() {
        for i in 0..<playerViews.count {
            playerViews[i].removeObserver(self.playerViewObserver)
            playerViews[i].willMove(toParentViewController: nil)
            playerViews[i].view.removeFromSuperview()
            playerViews[i].removeFromParentViewController()
        }
        playerViews = []
        let w = scrollView.frame.width
        let h = scrollView.frame.height
        let tracks = [player?.previousTrack, player?.currentTrack, player?.nextTrack].filter { $0 != nil}.map { $0! }
        tracks.enumerated().forEach { i, track in
            var pvc: PlayerViewController = PVC(player: player)
            self.addChildViewController(pvc)
            pvc.view.frame = CGRect(x:  w * CGFloat(i), y: 0, width: w, height: h)
            pvc.updateViewWithTrack(track, animated: false)
            pvc.addObserver(self.playerViewObserver)
            scrollView.addSubview(pvc.view)
            pvc.didMove(toParentViewController: self)
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

    @objc open func close() {
        coverViewController?.minimizeCeilingView(true)
    }

    open func toggle() {
        player?.toggle()
    }

    open func next() {
        let w = scrollView.frame.width
        let h = scrollView.frame.height
        if let _  = player?.previousTrack {
            scrollView.scrollRectToVisible(CGRect(x: 2 * w, y: 0, width: w, height: h), animated: true)
        } else {
            scrollView.scrollRectToVisible(CGRect(x:     w, y: 0, width: w, height: h), animated: true)
        }
    }

    open func previous() {
        let w = scrollView.frame.width
        let h = scrollView.frame.height
        scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: w, height: h), animated: true)
    }
    
    open var thumbnailView: UIView {
        return imageView
    }

    open func viewDidMaximize() {
        updateViews()
        if let playerViewController = currentPlayerView {
            playerViewController.videoView?.playerView = player.playerView
        }
    }

    open func viewDidMinimize() {
        updateViews()
        guard let track = player?.currentTrack else { return }
        track.loadThumbnailImage() { image in
            if let image = image, self.player.state == .pause {
                self.videoView.playerView = nil
                self.imageView.image = image
            } else {
                self.videoView.playerView = self.player.playerView
            }
        }
    }

    open func updateViewWithRate(_ rate: CGFloat) {
        miniPlayerView.updateViewWithRate(rate)
        let alpha = 0.75 * (1 - rate) + 0.25
        imageView.alpha = alpha
        videoView.alpha = alpha
    }

    open func timeUpdated() {
        guard let view = currentPlayerView else { return }
        view.timeUpdated()
        miniPlayerView.updateViewWithPlayer(player)
    }
    
    open func updateViews(_ animated: Bool = false) {
        guard let track = player?.currentTrack else {
            imageView.image  = self.defaultThumbImage
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
        switch (track.playerType, track.isVideo) {
        case (.normal, true):
            switch player.state {
            case .play, .pause:
                videoView.player = player.avPlayer
                imageView.image = videoBackgroundImage
            default:
                break
            }
        case (.youtube, _):
            guard let state = coverViewController?.ceilingViewControllerState else { return }
            guard let playerViewController = currentPlayerView else { return }
            switch state {
            case .maximized:
                playerViewController.videoView?.playerView = player.playerView
            case .minimized:
                track.loadThumbnailImage() { image in
                    if let image = image, self.player.state == .pause {
                        self.videoView.playerView = nil
                        self.imageView.image = image
                    } else if self.videoView.playerView == nil {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.35) {
                            self.videoView.playerView = self.player.playerView
                        }
                    }
                }
            default:
                break
            }
        default:
            track.loadThumbnailImage() { image in
                if let image = image {
                    self.videoView.player = nil
                    self.imageView.image = image
                } else {
                    self.videoView.player = nil
                    self.imageView.image  = self.defaultThumbImage
                }
            }
        }
    }

    open func changeTime(_ time: TimeInterval) {
        player?.seekToTime(time)
    }

    open func onMessage(_ message: String) {
    }
    
    open func enablePlayerView() {
        currentPlayerView?.enablePlayerView()
        guard let avPlayer = player.avPlayer else { return }
        if videoView.player != avPlayer {
            videoView.player = avPlayer
        }
    }
    open func disablePlayerView() {
        currentPlayerView?.disablePlayerView()
        videoView.player = nil
    }

    fileprivate func didScrollEnd() {
        let dst = scrollView.currentPage
        let current = player?.previousTrack == nil ? 0 : 1
        if dst < current {
            player?.previous()
        } else if dst > current {
            player?.next()
        }
    }
    
    // MARK: UIScrollViewDelegate

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didScrollEnd()
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        didScrollEnd()
    }

    // MARK: - MiniPlayerViewDelegate -

    open func miniPlayerViewPlayButtonTouched() {
        player?.toggle()
    }

    open func miniPlayerViewPreviousButtonTouched() {
        player?.previous()
    }

    open func miniPlayerViewNextButtonTouched() {
        player?.next()
    }

    open func miniPlayerViewUpdate() {
        updateViews()
    }

    public func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        view.addGestureRecognizer(gestureRecognizer)
    }
    public func canSwipeCeilingView(touch: UITouch) -> Bool {
        return true
    }
}
