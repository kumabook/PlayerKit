//
//  CoverExampleViewController.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/28.
//

import UIKit
import PlayerKit

class CoverExampleViewController: CoverViewController {
    var player: QueuePlayer!

    convenience init(player: QueuePlayer) {
        let mainViewController = TrackTableViewController(nibName: nil, bundle: nil)
        let miniPlayerViewController = MiniPlayerViewController<SimpleMiniPlayerView>.init(player: player)
        miniPlayerViewController.mainViewController = mainViewController
        let playerPageViewController = PlayerPageViewController<SimplePlayerViewController, SimpleMiniPlayerView>(player: player)
        self.init(ceilingViewController: playerPageViewController, floorViewController: miniPlayerViewController)
        self.player = player
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
