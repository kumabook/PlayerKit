//
//  PlayerView.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 3/2/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import AVFoundation

public class PlayerView: UIButton {
    public var player: AVPlayer? {
        get {
            let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
            return layer.player
        }
        set(newValue) {
            let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
            layer.player = newValue
        }
    }

    override public class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
}
