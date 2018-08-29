//
//  AppDelegate.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/28.
//

import UIKit
import PlayerKit

extension UIViewController {
    var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let player: QueuePlayer = QueuePlayer()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        player.addPlayer(YouTubePlayer())
        window?.rootViewController = UINavigationController(rootViewController: ExampleTableViewController(player: player))
        return true
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

