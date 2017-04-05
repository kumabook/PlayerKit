//
//  YouTubePlayer.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/04/03.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation
import YouTubeiOSPlayerHelper

open class YouTubePlayer: NSObject, ServicePlayer {
    public typealias ObserverType = ServicePlayerObserver
    public typealias EventType    = ServicePlayerEvent
    fileprivate var _observers: [ObserverType] = []
    open  var  observers: [ObserverType] {
        get { return _observers }
        set { _observers = newValue }
    }
    public var track: Track?
    open var state: PlayerState {
        didSet {
            if oldValue != state {
                notify(.statusChanged)
            }
        }
    }
    public private(set) var playerView: YTPlayerView
    fileprivate var endProxy: ObserverProxy?
    
    public override init() {
        track = nil
        state = .init
        playerView = YTPlayerView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        super.init()
        playerView.delegate = self
        playerView.isUserInteractionEnabled = false
        endProxy = ObserverProxy(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                 closure: self.playerDidPlayToEndTime)
    }
    
    func playerDidPlayToEndTime(_ notification: Notification) {
        notify(.didPlayToEndTime)
    }
    
    // MARK: QueuePlayer protocol
    open var playerType:  PlayerType   { return PlayerType.youtube }
    open var playingInfo: PlayingInfo? {
        return PlayingInfo(duration: playerView.duration(), elapsedTime: TimeInterval(playerView.currentTime()))
    }
    
    open func seekToTime(_ time: TimeInterval) {
        playerView.seek(toSeconds: Float(time), allowSeekAhead: true)
    }
    
    open func keepPlaying() {
    }
    
    open func play() {
        state = .loadToPlay
        playerView.playVideo()
        state = .play
    }
    
    open func pause() {
        playerView.pauseVideo()
        state = .pause
    }
    
    open func clearPlayer() {
        playerView.pauseVideo()
        state = .pause
        endProxy?.stop()
    }
    
    open func preparePlayer() {
        guard let videoId = track?.youtubeVideoID else { return }
        switch playerView.playerState() {
        case .unknown:
            playerView.load(withVideoId: videoId, playerVars: [
                "playsinline"   : 1,
                "showinfo"      : 0,
                "rel"           : 0,
                "modestbranding": 1,
                "controls"      : 0,
                "origin"        : "https://www.example.com"
                ])
        default:
            playerView.cueVideo(byId: videoId, startSeconds: 0, suggestedQuality: YTPlaybackQuality.auto)
        }
        endProxy?.start()
    }
}

extension YouTubePlayer: YTPlayerViewDelegate {
    public func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        switch state {
        case .loadToPlay, .play:
            playerView.playVideo()
        default:
            state = .load
        }
    }
    public func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        switch state {
        case .paused:
            self.state = .pause
        case .playing:
            self.state = .play
        default:
            break
        }
    }
    
    public func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        notify(.timeUpdated)
    }
    public func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
        notify(.errorOccured)
        state = .pause
    }
}

