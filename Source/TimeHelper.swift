//
//  TimeHelper.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 3/2/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import Foundation

public struct TimeHelper {
    public static func timeStr(sec: Float) -> String {
        if sec < 0 {
            return "00:00"
        }
        return String(format:"%02d:%02d", Int(floor(sec / 60)), Int(floor(sec % 60)))
    }

    public static func trackTimeStr(currentSec currentSec: Float, totalSec: Float) -> String {
        return "\(timeStr(currentSec))/\(timeStr(totalSec)))"
    }
}