//
//  Position.swift
//  EP Calipers
//
//  Created by David Mann on 9/30/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Cocoa

class Position: NSObject {
    static func translateToAbsolutePosition(scaledPosition position: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return position / scale + offset
    }
    
    static func translateToScaledPosition(absolutePosition position: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return scale * (position - offset)
    }
}
