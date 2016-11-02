//
//  Track.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/26/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import Foundation

public protocol Track {
    var title:        String? { get }
    var subtitle:     String? { get }
    var streamUrl:    URL?  { get }
    var thumbnailUrl: URL?  { get }
    var artworkUrl:   URL?  { get }
    var isVideo:      Bool    { get }
    var isValid:      Bool    { get }
}

extension Track {
    public var isValid: Bool { return streamUrl != nil }
}
