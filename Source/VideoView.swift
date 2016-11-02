//
//  VideoView.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 6/18/16.
//  Copyright © 2016 kumabook. All rights reserved.
//

import UIKit
import AVFoundation

open class VideoView: UIButton {
    open var player: AVPlayer? {
        get {
            guard let layer = self.layer as? AVPlayerLayer else { return nil }
            return layer.player
        }
        set(newValue) {
            guard let layer = self.layer as? AVPlayerLayer else { return }
            layer.player = newValue
        }
    }
    
    override open class var layerClass : AnyClass {
        return AVPlayerLayer.self
    }
}
