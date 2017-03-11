//
//  Playlist.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/26/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import Foundation

public protocol Playlist {
    var id:               String { get }
    var tracks:           [Track] { get }
    var validTracksCount: Int { get }
}
