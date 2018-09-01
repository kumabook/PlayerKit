//
//  AppDelegate.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/28.
//

import UIKit
import AVFoundation
import PlayerKit

extension UIViewController {
    var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var player: QueuePlayer!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try? audioSession.setActive(true)
        UIApplication.shared.beginReceivingRemoteControlEvents()

        player = QueuePlayer()
        SpotifyAPIClient.setup()
        AppleMusicClient.shared.connect(silent: true).start()
        player.addPlayer(YouTubePlayer())
        player.addPlayer(SpotifyPlayer())
        player.observeCommandCenter()
        player.addObserver(NowPlayingInfoCenter(player: player))

        window?.rootViewController = UINavigationController(rootViewController: ExampleTableViewController(player: player))
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return SpotifyAPIClient.shared.handleURL(url: url)
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
}

