//
//  PlayerSpec.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 9/20/15.
//  Copyright © 2015 kumabook. All rights reserved.
//

import XCTest
import Quick
import Nimble
@testable import PlayerKit

class PlayerSpec: QuickSpec {
    override func spec() {
        var player:   QueuePlayer!
        var observer: TestObserver!
        beforeEach {
            player   = QueuePlayer()
            observer = TestObserver()
            player.addObserver(observer)
        }
        func start() {
            let playlist = TestPlaylist()
            player.play(at: Index(track: 0, playlist: 0), in: PlaylistQueue(playlists: [playlist]))
        }
        func toggle() {
            player.toggle()
        }
        describe("Player") {
            it("should construct") {
                expect(player).notTo(beNil())
                expect(player.state).to(equal(PlayerState.init))
            }

            it("should play a track") {
                start()
                expect(observer.statusChangedCount).toEventually(beGreaterThan(1))
                expect(player.state).to(equal(PlayerState.play))
            }

            it("should stop a track") {
                start()
                expect(observer.statusChangedCount).toEventually(beGreaterThan(1))
                toggle()
                expect(observer.statusChangedCount).toEventually(beGreaterThan(2))
                expect(player.state).to(equal(PlayerState.pause))
            }
        }
    }
}
