//
//  ExampleTableViewController.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/28.
//

import UIKit
import PlayerKit

class ExampleTableViewController: UITableViewController, SpotifyAuthDelegate {
    var player: QueuePlayer!
    enum Section: Int {
        case examples    = 0
        case accounts    = 1
        static let count = 2
        var title: String {
            switch self {
            case .examples: return "Examples"
            case .accounts: return "Accounts"
            }
        }
    }
    enum ExampleRow: Int {
        case miniPlayer  = 0
        case cover       = 1
        static let count = 2
        var title: String {
            switch self {
            case .miniPlayer: return "MiniPlayer"
            case .cover:      return "Cover"
            }
        }
    }
    enum AccountRow: Int {
        case spotify     = 0
        case appleMusic  = 1
        static let count = 2
        var title: String {
            switch self {
            case .spotify:
                if SpotifyAPIClient.shared.isLoggedIn {
                    return "Spotify(Connected)"
                } else {
                    return "Spotify(Not connected)"
                }
            case .appleMusic:
                if #available(iOS 9.3, *) {
                    switch AppleMusicClient.shared.authroizationStatus {
                    case .notDetermined:
                        return "AppleMusic(Not connected)"
                    case .denied:
                        return "AppleMusic(Enable permission)"
                    case .restricted:
                        return "AppleMusic(Restricted)"
                    case .authorized:
                        return "AppleMusic(Connected)"
                    }
                } else {
                    return "AppleMusic(Need update to iOS 9.3 or later)"
                }
            }
        }
    }

    convenience init(player: QueuePlayer) {
        self.init(nibName: nil, bundle: nil)
        self.player = player
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Examples"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let section = Section(rawValue: section) {
            return section.title
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let section = Section(rawValue: section) {
            switch section {
            case .examples:
                return ExampleRow.count
            case .accounts:
                return AccountRow.count
            }
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "reuseIdentifier")
        if let section = Section(rawValue: indexPath.section) {
            switch section {
            case .examples:
                cell.textLabel?.text = ExampleRow(rawValue: indexPath.row)?.title
            case .accounts:
                cell.textLabel?.text = AccountRow(rawValue: indexPath.row)?.title
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let section = Section(rawValue: indexPath.section) {
            switch section {
            case .examples:
                switch ExampleRow(rawValue: indexPath.row)! {
                case .miniPlayer:
                    navigationController?.pushViewController(MiniPlayerExampleViewController(player: player), animated: true)
                case .cover:
                    navigationController?.pushViewController(CoverExampleViewController(player: player), animated: true)
                }
            case .accounts:
                switch AccountRow(rawValue: indexPath.row)! {
                case .spotify:
                    if SpotifyAPIClient.shared.isLoggedIn {
                        disconnectSpotify()
                    } else {
                        connectSpotify()
                    }
                case .appleMusic:
                    if #available(iOS 9.3, *) {
                        switch AppleMusicClient.shared.authroizationStatus {
                        case .notDetermined:
                            AppleMusicClient.shared.connect(silent: false).start()
                        case .denied:
                            UIApplication.shared.openURL(URL(string: "app-settings:")!)
                        default:
                            break
                        }
                    }
                }
            }
        }
    }

    func connectSpotify() {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        SpotifyAPIClient.shared.authDelegate = self
        SpotifyAPIClient.shared.startAuthenticationFlow(viewController: delegate?.window?.rootViewController ?? self)
    }

    func disconnectSpotify() {
        SpotifyAPIClient.shared.logout()
        tableView.reloadData()
    }

    func spotifyAuthDidLogin() {
        tableView.reloadData()
    }

    func spotifyAuthDidFailToLogin() {
        tableView.reloadData()
    }

    func spotifyAuthDidLogout() {
        tableView.reloadData()
    }
}
