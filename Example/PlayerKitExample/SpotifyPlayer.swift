//
//  SpotifyPlayer.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/31.
//

import Foundation
import MediaPlayer
import PlayerKit
import Spotify

class SpotifyPlayer: PlayerKit.SpotifyPlayer, SPTAudioStreamingPlaybackDelegate {
    public fileprivate(set) var streamingController: SPTAudioStreamingController

    override init() {
        streamingController = SPTAudioStreamingController.sharedInstance()
        super.init()
    }

    @objc func updateTime() {
        notify(.timeUpdated)
    }

    // MARK: SPTAudioStreamingPlaybackDelegate

    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if state == .play && !isPlaying {
            state = .pause
        }
    }

    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        switch state {
        case .loadToPlay: state = .play
        default:          break
        }
        notify(.timeUpdated)
    }

    func  audioStreamingDidPopQueue(_ audioStreaming: SPTAudioStreamingController!) {
        notify(.didPlayToEndTime)
    }

    // MARK: QueuePlayer protocol
    override var playerType:  PlayerType     { return PlayerType.appleMusic }
    override var playingInfo: PlayingInfo? {
        if let track = streamingController.metadata?.currentTrack {
            return PlayingInfo(duration: track.duration,
                               elapsedTime: streamingController.playbackState?.position ?? 0.0)
        }
        return nil
    }

    override func seekToTime(_ time: TimeInterval) {
        if !streamingController.loggedIn { return }
        streamingController.seek(to: time) { e in
            if let e = e {
//                print("spotify seek error \(e)")
                self.notify(.errorOccured)
                return
            }
            self.notify(.timeUpdated)
        }
        
    }

    open func keepPlaying() {
        if state.isPlaying {
            play()
        }
    }

    override func play() {
        if !streamingController.loggedIn { return }
        state = .loadToPlay
        streamingController.setIsPlaying(true) { e in
            if let e = e {
//                print("spotify setIsPlaying error \(e)")
                self.notify(.errorOccured)
                return
            }
        }
    }

    open override func pause() {
        if !streamingController.loggedIn { return }
        state = .load
        streamingController.setIsPlaying(false) { e in
            self.state = .pause
            if let e = e {
//                print("spotify setIsPlaying error \(e)")
                self.notify(.errorOccured)
                return
            }
        }
    }

    override func clearPlayer() {
        if !streamingController.loggedIn { return }
        streamingController.setIsPlaying(false) { e in }
        streamingController.playbackDelegate = nil
    }

    override func preparePlayer() {
        if !streamingController.loggedIn { return }
        guard let track = track, let uri = track.spotifyURI, track.isValid else { return }
        streamingController.playbackDelegate = self
        streamingController.seek(to: 0.0) { e in }
        streamingController.playSpotifyURI(uri, startingWith: 0, startingWithPosition: 0) { e in
            switch self.state {
            case .loadToPlay, .play:
                self.streamingController.setIsPlaying(true) {e in }
            default:
                self.streamingController.setIsPlaying(false) {e in }
            }
            if let e = e {
//                print("Failed to play uri \(uri): \(e)")
                self.notify(.errorOccured)
                return
            }
        }
    }
}
