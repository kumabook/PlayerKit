//
//  Player.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/03/12.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation

public protocol Player {
    var playingInfo: PlayingInfo? { get }
    var playerType:  PlayerType { get }
    var state:       PlayerState { get }
    func clearPlayer()
    func preparePlayer()
    func pause()
    func play()
    func play(_ track: Track)
    func prepare(for: Track)
    func seekToTime(_ time: TimeInterval)
    func toggle()
}
