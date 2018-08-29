//
//  MiniPlayerExampleViewController.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/28.
//

import UIKit
import AVFoundation
import MediaPlayer
import PlayerKit

class MiniPlayerExampleViewController: PlayerKit.MiniPlayerViewController<PlayerKit.SimpleMiniPlayerView> {
    open var minThumbnailHeight: CGFloat { return 60.0 }
    open var thumbWidth:         CGFloat = 75.0
    var videoView: VideoView!

    override init(player: QueuePlayer) {
        super.init(player: player)
        mainViewController = TrackTableViewController(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.red
        videoView            = VideoView()
        videoView.frame      = CGRect(x: 0, y: 0, width: thumbWidth, height: minThumbnailHeight)
        miniPlayerView.addSubview(videoView)
        view.addSubview(miniPlayerView)
        videoView.player = player?.avPlayer
        videoView.playerView = player?.playerView
        self.showMiniPlayer(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
