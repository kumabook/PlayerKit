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
        var player:   Player!
        var observer: TestObserver!
        beforeEach {
            player   = Player()
            observer = TestObserver()
            player.addObserver(observer)
        }
        func start() {
            let playlist = TestPlaylist()
            player.play(trackIndex: 0, playlistIndex: 0, playlists: [playlist])
        }
        func toggle() {
            player.toggle()
        }
        describe("Player") {
            it("should construct") {
                expect(player).notTo(beNil())
                expect(player.currentState).to(equal(PlayerState.Init))
            }

            it("should play a track") {
                start()
                expect(observer.statusChangedCount).toEventually(beGreaterThan(1))
                expect(player.currentState).to(equal(PlayerState.Play))
            }

            it("should stop a track") {
                start()
                expect(observer.statusChangedCount).toEventually(beGreaterThan(1))
                toggle()
                expect(observer.statusChangedCount).toEventually(beGreaterThan(2))
                expect(player.currentState).to(equal(PlayerState.Pause))
            }
        }
    }
}
