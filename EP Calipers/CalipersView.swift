//
//  CalipersView.swift
//  EP Calipers
//
//  Created by David Mann on 1/3/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa

class CalipersView: NSView {
    
//    override func mouseDown(theEvent: NSEvent) {
//        superview!.mouseDown(theEvent)
//    }
//    
//    override func mouseDragged(theEvent: NSEvent) {
//        superview!.mouseDragged(theEvent)
//    }
//    
//    override func mouseUp(theEvent: NSEvent) {
//        superview!.mouseUp(theEvent)
//    }
//    
//    override func hitTest(aPoint: NSPoint) -> NSView? {
//        return superview
//    }
//    
    override func drawRect(dirtyRect: NSRect) {
        let backgroundColor = NSColor.clearColor()
        backgroundColor.set()
        NSBezierPath.fillRect(bounds)
    }
        
}

