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
import SDWebImage

class MiniPlayerObserver: PlayerObserver {
    let delegate: MiniPlayerViewDelegate
    init(miniPlayerViewDelegate: MiniPlayerViewDelegate) {
        delegate = miniPlayerViewDelegate
        super.init()
    }
    override func listen(_ event: Event) {
        switch event {
        case .timeUpdated:              delegate.miniPlayerViewUpdate()
        case .didPlayToEndTime:         delegate.miniPlayerViewUpdate()
        case .statusChanged:            delegate.miniPlayerViewUpdate()
        case .trackSelected(_, _, _):   delegate.miniPlayerViewUpdate()
        case .trackUnselected(_, _, _): delegate.miniPlayerViewUpdate()
        default:                        delegate.miniPlayerViewUpdate()
        }
    }
}

open class MiniPlayerViewController<MV: MiniPlayerView>: UIViewController, MiniPlayerViewDelegate {
    open var miniPlayerHeight: CGFloat { return 60.0 }
    open var mainViewController: UIViewController?
    var miniPlayerObserver:      MiniPlayerObserver!
    open var player:             QueuePlayer?
    open var mainViewContainer:  UIView!
    open var miniPlayerView:     MV!

    public init(player: QueuePlayer) {
        super.init(nibName: nil, bundle: nil)
        self.player = player
        miniPlayerObserver = MiniPlayerObserver(miniPlayerViewDelegate: self)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        let w = view.frame.width
        let h = view.frame.height - miniPlayerHeight
        mainViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: w, height: h))
        miniPlayerView    = MV(frame: CGRect(x: 0, y: h, width: w, height: miniPlayerHeight))
        view.addSubview(mainViewContainer)
        view.addSubview(miniPlayerView)

        if let vc = mainViewController {
            addChildViewController(vc)
            vc.view.frame = mainViewContainer.bounds
            vc.didMove(toParentViewController: self)
            miniPlayerView.delegate = self
            mainViewContainer.addSubview(vc.view)
            view.bringSubview(toFront: miniPlayerView)
            updateViews()
            player?.addObserver(miniPlayerObserver)
        }
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    open func updateViews() {
        guard let player = player else { return }
        miniPlayerView.state = player.currentState
        miniPlayerView.updateViewWithPlayer(player)
    }

    open func hideMiniPlayer(_ animated: Bool, completion: @escaping (Bool) -> () = {_ in }) {
        let action = {
            let w = self.view.frame.width
            let h = self.view.frame.height
            self.mainViewContainer.frame = CGRect(x: 0, y: 0, width: w, height: h)
            self.miniPlayerView.frame = CGRect(x: 0, y: h, width: w, height: self.miniPlayerHeight)
        }
        if animated {
            let d = CoverViewController.toggleAnimationDuration
            UIView.animate(withDuration: d, delay: 0, options:UIViewAnimationOptions(), animations: action, completion: completion)
        } else {
            action()
            completion(true)
        }
    }
    
    open func showMiniPlayer(_ animated: Bool, completion: @escaping (Bool) -> () = {_ in }) {
        let action = {
            let w = self.view.frame.width
            let h = self.view.frame.height - self.miniPlayerHeight
            self.mainViewContainer.frame = CGRect(x: 0, y: 0, width: w, height: h)
            self.miniPlayerView.frame = CGRect(x: 0, y: h, width: w, height: self.miniPlayerHeight)
        }
        if animated {
            let d = CoverViewController.toggleAnimationDuration
            UIView.animate(withDuration: d, delay: 0, options:UIViewAnimationOptions(), animations: action, completion: completion)
        } else {
            action()
            completion(true)
        }
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
}
