//
//  CalipersView.swift
//  EP Calipers
//
//  Created by David Mann on 1/3/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa

class CalipersView: NSView {
//    override init(frame frameRect: NSRect) {
//        
//        super.init(frame: frameRect)
//        acceptsTouchEvents = false
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        acceptsTouchEvents = false
//
//    }
    
//    override func mouseDown(theEvent: NSEvent) {
//        NSLog("MouseDown")
//        superview!.mouseDown(theEvent)
//    }
//    
//    override func mouseDragged(theEvent: NSEvent) {
//        NSLog("MouseDragged")
//        superview!.mouseDragged(theEvent)
//    }
//    
//    override func mouseUp(theEvent: NSEvent) {
//        NSLog("MouseUp")
//        superview!.mouseUp(theEvent)
//    }
    
    override func drawRect(dirtyRect: NSRect) {
        let backgroundColor = NSColor.redColor().colorWithAlphaComponent(0.3)
        backgroundColor.set()
        NSBezierPath.fillRect(bounds)
    }
 
    
    //    override func magnifyWithEvent(event: NSEvent) {
//        NSLog("Zoom gesture")
//        superview!.magnifyWithEvent(event)
//    }

}

