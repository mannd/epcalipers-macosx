//
//  CalipersView.swift
//  EP Calipers
//
//  Created by David Mann on 1/3/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa
import Quartz

class CalipersView: NSView {
    
    var imageView: IKImageView? = nil
    var calipersMode: Bool = false
    
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
    
    override func mouseDown(theEvent: NSEvent) {
        NSLog("MouseDown")
        if !calipersMode {
            imageView!.mouseDown(theEvent)
        }
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        NSLog("MouseDragged")
        if !calipersMode {
            imageView!.mouseDragged(theEvent)
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        NSLog("MouseUp")
        if !calipersMode {
            imageView!.mouseUp(theEvent)
        }
    }
    
    override func magnifyWithEvent(event: NSEvent) {
        NSLog("Zoom gesture")
        imageView!.magnifyWithEvent(event)
    }

    
    override func drawRect(dirtyRect: NSRect) {
        let backgroundColor = NSColor.redColor().colorWithAlphaComponent(0.3)
        backgroundColor.set()
        NSBezierPath.fillRect(bounds)
    }
 
    

}

