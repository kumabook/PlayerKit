//
//  ExampleTableViewController.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/28.
//

import UIKit
import PlayerKit

class ExampleTableViewController: UITableViewController {
    var player: QueuePlayer!
    enum Row: Int {
        case miniPlayer      = 0
        case cover           = 1
        static let count     = 2
        var title: String {
            switch self {
            case .miniPlayer:      return "MiniPlayer"
            case .cover:           return "Cover"
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
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Row.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "reuseIdentifier")
        if let row = Row(rawValue: indexPath.row) {
            cell.textLabel?.text = row.title
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let row = Row(rawValue: indexPath.row) {
            switch row {
            case .miniPlayer:
                navigationController?.pushViewController(MiniPlayerExampleViewController(player: player), animated: true)
            case .cover:
                navigationController?.pushViewController(CoverExampleViewController(player: player), animated: true)
            }
        }
    }
}
