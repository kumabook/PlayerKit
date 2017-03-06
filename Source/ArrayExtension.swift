//
//  ArrayExtension.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 2017/03/07.
//  Copyright © 2017 kumabook. All rights reserved.
//

import Foundation

extension Array {
    public func get(_ index: Int) -> Element? {
        if 0 <= index && index < self.count {
            return self[index]
        } else {
            return nil
        }
    }
}
