//
//  TimeHelper.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 3/2/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import Foundation

struct TimeHelper {
    static func timeStr(sec: Float) -> String {
        return String(format:"%02d:%02d", Int(floor(sec / 60)), Int(floor(sec % 60)))
    }

    static func trackTimeStr(#currentSec: Float, totalSec: Float) -> String {
        return "\(timeStr(currentSec))/\(timeStr(totalSec)))"
    }
}