//
//  Track.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/26/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import Foundation
import UIKit

public protocol Track {
    var title:             String?    { get }
    var subtitle:          String?    { get }
    var isVideo:           Bool       { get }
    var isValid:           Bool       { get }
    var canPlayBackground: Bool       { get }
    var playerType:        PlayerType { get }
    var streamURL:         URL?       { get }
    var appleMusicID:      String?    { get }
    var spotifyURI:        String?    { get }
    var youtubeVideoID:    String?    { get }

    func loadThumbnailImage(completeHandler: (UIImage?) -> Void)
    func loadArtworkImage(completeHandler: (UIImage?) -> Void)
}

