//
//  TrackQueue.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/03/09.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation

public struct TrackList: Equatable {
    public var id:     String
    public var tracks: [Track]
    public subscript(index: Int) -> Track {
        get {
            return tracks[index]
        }
        set(newValue) {
            tracks[index] = newValue
        }
    }
    public var count: Int { return tracks.count }
    public init(id: String, tracks: [Track]) {
        self.id     = id
        self.tracks = tracks
    }
}

public func ==(lhs: TrackList, rhs: TrackList) -> Bool {
    return lhs.id.isEqual(rhs.id)
}
