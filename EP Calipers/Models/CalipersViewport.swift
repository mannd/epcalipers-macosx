//
//  CalipersViewport.swift
//  EP Calipers
//
//  Created by David Mann on 5/20/26.
//  Copyright © 2026 EP Studios. All rights reserved.
//

import Cocoa

struct CalipersViewport {
    var magnification: CGFloat
    var offset: CGPoint

    func absolutePosition(fromScaledPosition position: CGFloat, axisOffset: CGFloat) -> CGFloat {
        position / magnification + axisOffset
    }

    func scaledPosition(fromAbsolutePosition position: CGFloat, axisOffset: CGFloat) -> CGFloat {
        magnification * (position - axisOffset)
    }
}
