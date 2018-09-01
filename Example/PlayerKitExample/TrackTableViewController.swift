//
//  TrackTableViewController.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/28.
//

import UIKit
import PlayerKit

class TrackTableViewController: UITableViewController {
    var spotifyUri = "spotify:track:0Cq2ATRupKEGuKoNXUB1tv"
    var appleMusicSongID = "1320755082"
    var tracks: [Track] = [
        YouTubeTrack(title: "SIRUP - SWIM / TOKYO SOUNDS（Music Bar Session）",
                     channelName: "Spincoaster",
                     identifier: "TmjGdJD8i5E"),
    ]

    func loadLocalVideo() {
        let url = Bundle.main.url(forResource: "vol-08", withExtension: "mp4")
        tracks.append(AVItemTrack(title: "SPIN.DISCOVERY VOL.08", channelName: "Spincoaster", streamURL: url!))
    }

    func fetchSpotifyTrack() {
        SpotifyAPIClient.shared.track(from: URL(string: spotifyUri)!).startWithResult { [weak self] in
            if let e = $0.error {
                print("\(e)")
                return
            }
            self?.tracks.append($0.value!)
            self?.tableView.reloadData()
        }
    }

    func fetchAppleMusicSong() {
        AppleMusicClient.shared.song(id: appleMusicSongID).startWithResult { [weak self] in
            if let e = $0.error {
                print("\(e)")
                return
            }
            self?.tracks.append($0.value!)
            self?.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadLocalVideo()
        fetchSpotifyTrack()
        fetchAppleMusicSong()
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
