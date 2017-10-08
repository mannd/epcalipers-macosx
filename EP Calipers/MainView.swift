//
//  MainView.swift
//  EP Calipers
//
//  Created by David Mann on 1/17/17.
//  Copyright © 2017 EP Studios. All rights reserved.
//

import Cocoa

class MainView: NSView {
    
    let headerHeight: CGFloat = 60.0  // based on xib file constraints

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let rect = NSRect(x: dirtyRect.minX, y: dirtyRect.minY, width:dirtyRect.maxX - dirtyRect.minX, height: dirtyRect.maxY - dirtyRect.minY - headerHeight)
        rect.fill(using: NSCompositingOperation.clear)

    }
    
}
