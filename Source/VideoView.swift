//
//  VideoView.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/18/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import UIKit
import AVFoundation

public class VideoView: UIButton {
    public var player: AVPlayer? {
        get {
            guard let layer = self.layer as? AVPlayerLayer else { return nil }
            return layer.player
        }
        set(newValue) {
            guard let layer = self.layer as? AVPlayerLayer else { return }
            layer.player = newValue
        }
    }
    
    override public class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
}
