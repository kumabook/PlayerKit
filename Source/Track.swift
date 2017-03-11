//
//  Track.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/26/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import Foundation

public protocol Track {
    var title:        String?    { get }
    var subtitle:     String?    { get }
    var thumbnailURL: URL?       { get }
    var artworkURL:   URL?       { get }
    var isVideo:      Bool       { get }
    var isValid:      Bool       { get }
    var playerType:   PlayerType { get }
    var streamURL:    URL?       { get }
    var appleMusicID: String?    { get }
    var spotifyURI:   String?    { get }
}

extension Track {
    public var isValid:      Bool    { return streamURL != nil }
    public var appleMusicID: String? { return nil }
    public var spotifyURI:   String? { return nil }
}
