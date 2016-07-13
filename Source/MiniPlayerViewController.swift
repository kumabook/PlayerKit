//
//  MiniPlayerViewController.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 12/28/14.
//  Copyright (c) 2014 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import SnapKit
import WebImage

class MiniPlayerObserver: PlayerObserver {
    let delegate: MiniPlayerViewDelegate
    init(miniPlayerViewDelegate: MiniPlayerViewDelegate) {
        delegate = miniPlayerViewDelegate
        super.init()
    }
    override func listen(event: Event) {
        switch event {
        case .TimeUpdated:              delegate.miniPlayerViewUpdate()
        case .DidPlayToEndTime:         delegate.miniPlayerViewUpdate()
        case .StatusChanged:            delegate.miniPlayerViewUpdate()
        case .TrackSelected(_, _, _):   delegate.miniPlayerViewUpdate()
        case .TrackUnselected(_, _, _): delegate.miniPlayerViewUpdate()
        default:                        delegate.miniPlayerViewUpdate()
        }
    }
}

public class MiniPlayerViewController<MV: MiniPlayerView>: UIViewController, MiniPlayerViewDelegate {
    public let miniPlayerHeight: CGFloat = 60.0
    public var mainViewController: UIViewController?
    var miniPlayerObserver:        MiniPlayerObserver!
    public var player:             Player?
    public var mainViewContainer:  UIView!
    public var miniPlayerView:     MV!

    public init(player: Player) {
        super.init(nibName: nil, bundle: nil)
        self.player = player
        miniPlayerObserver = MiniPlayerObserver(miniPlayerViewDelegate: self)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        let w = view.frame.width
        let h = view.frame.height - miniPlayerHeight
        mainViewContainer    = UIView(frame: CGRectMake(0, 0, w, h))
        miniPlayerView       = MV(frame: CGRectMake(0, h, w, miniPlayerHeight))
        view.addSubview(mainViewContainer)
        view.addSubview(miniPlayerView)

        if let vc = mainViewController {
            addChildViewController(vc)
            vc.view.frame = mainViewContainer.bounds
            vc.didMoveToParentViewController(self)
            miniPlayerView.delegate = self
            mainViewContainer.addSubview(vc.view)
            view.bringSubviewToFront(miniPlayerView)
            updateViews()
            player?.addObserver(miniPlayerObserver)
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public func updateViews() {
        guard let player = player else { return }
        miniPlayerView.state = player.currentState
        miniPlayerView.updateViewWithPlayer(player)
    }

    public func hideMiniPlayer(animated: Bool, completion: (Bool) -> () = {_ in }) {
        let action = {
            let w = self.view.frame.width
            let h = self.view.frame.height
            self.mainViewContainer.frame = CGRectMake(0, 0, w, h)
            self.miniPlayerView.frame = CGRectMake(0, h, w, self.miniPlayerHeight)
        }
        if animated {
            let d = CoverViewController.toggleAnimationDuration
            UIView.animateWithDuration(d, delay: 0, options:.CurveEaseInOut, animations: action, completion: completion)
        } else {
            action()
            completion(true)
        }
    }
    
    public func showMiniPlayer(animated: Bool, completion: (Bool) -> () = {_ in }) {
        let action = {
            let w = self.view.frame.width
            let h = self.view.frame.height - self.miniPlayerHeight
            self.mainViewContainer.frame = CGRectMake(0, 0, w, h)
            self.miniPlayerView.frame = CGRectMake(0, h, w, self.miniPlayerHeight)
        }
        if animated {
            let d = CoverViewController.toggleAnimationDuration
            UIView.animateWithDuration(d, delay: 0, options:.CurveEaseInOut, animations: action, completion: completion)
        } else {
            action()
            completion(true)
        }
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
