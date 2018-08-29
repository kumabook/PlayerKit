//
//  TrackTableViewController.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/28.
//

import UIKit
import PlayerKit

class TrackTableViewController: UITableViewController {
    var tracks: [Track] = [
        YouTubeTrack(title: "SIRUP - SWIM / TOKYO SOUNDS（Music Bar Session）", channelName: "Spincoaster", identifier: "TmjGdJD8i5E"),
        AVItemTrack(title: "トリコ", channelName: "Nissy", streamURL: URL(string: "https://p.scdn.co/mp3-preview/2a54146a9ca4ace1545d9d8f61d4cad6cc5e3c86?cid=7cadd9a921cd4b55bbce316055609e75")!)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "reuseIdentifier")
        cell.textLabel?.text = tracks[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playlist = MultiServicePlaylist.init(id: "example", tracks: tracks)
        appDelegate?.player.play(at: Index(track: indexPath.row, playlist: 0), in: PlaylistQueue(playlists: [playlist]))
    }
}
