//
//  CalipersView.swift
//  EP Calipers
//
//  Created by David Mann on 1/3/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa
import Quartz

// TODO: Locked mode - lock image so it can't be moved by the mouse, only allowing
// calipers to be moved.  Might be useful to avoid inadvertent moving of ECG when
// trying to move calipers.
class CalipersView: NSView {
    
    var imageView: IKImageView? = nil
    var calipersMode: Bool = false
    var calipers: [Caliper] = []
    // new lockedMode variable?
    var lockedMode: Bool = false
    // not sure if still need this
    var locked: Bool = false
    var selectedCaliper: Caliper? = nil
    
    
//    override init(frame frameRect: NSRect) {
//        
//        super.init(frame: frameRect)
//        acceptsTouchEvents = false
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        // have gesturerecognizers in iOS version
//        // clearsContextBeforeDrawing = false ?? iOS/UIView only property?
//        locked = false  // declared above as false
//    }
  
// See Tracking-Area Objects for possible equivalence of below in Mac OS X
// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/EventOverview/TrackingAreaObjects/TrackingAreaObjects.html
//   - (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
//    for (int i = (int)self.calipers.count - 1; i >= 0; i--) {
//    if ([(Caliper *)self.calipers[i] pointNearCaliper:point]) {
//    return YES;
//    }
//    }
//    return NO;
//}
    
// Not clear if below used, or has equivalence in Mac OS X
//        - (void)drawRect:(CGRect)rect {
//    CGContextRef con = UIGraphicsGetCurrentContext();
//    for (Caliper *caliper in self.calipers) {
//    [caliper drawWithContext:con inRect:rect];
//    }

    func selectCaliper(c: Caliper) {
        c.color = c.selectedColor
        c.selected = true
        needsDisplay = true
    }
    
    func unselectCaliper(c: Caliper) {
        c.color = c.unselectedColor
        c.selected = false
        needsDisplay = true
    }

// TDOD: Movement functions to be implemented

    override func mouseDown(theEvent: NSEvent) {
        NSLog("MouseDown")
        if theEvent.clickCount == 2 {
            NSLog("Double Click")
        }
        if theEvent.clickCount == 1 {
            NSLog("Single Click")
        }
        selectedCaliper = nil
        for c in calipers {
                if c.pointNearCaliper(theEvent.locationInWindow) && selectedCaliper == nil {
                    selectedCaliper = c
            }
        }
        if selectedCaliper != nil {
            NSLog("Near caliper")
        }
        else {
            imageView!.mouseDown(theEvent)
        }
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        NSLog("MouseDragged")
        if selectedCaliper == nil {
            imageView!.mouseDragged(theEvent)
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        NSLog("MouseUp")
        if let c = selectedCaliper {
            if theEvent.clickCount == 1 {
                if c.selected {
                    unselectCaliper(c)
                }
                else {
                    selectCaliper(c)
                }
            }
            else {
                unselectCaliper(c)
            }
        selectedCaliper = nil
        }
        else {
            imageView!.mouseUp(theEvent)
        }
    }
    
    func toggleCaliperState() {
        if let c = selectedCaliper {
            if c.selected {
                unselectCaliper(c)
            }
            else {
                selectCaliper(c)
            }
            // unselect all the other calipers
            for cal in calipers {
                if cal != c {
                    unselectCaliper(cal)
                }
            }
            selectedCaliper = nil
        }
        

    }
 
    override func magnifyWithEvent(event: NSEvent) {
        NSLog("Zoom gesture")
        imageView!.magnifyWithEvent(event)
    }

    
    override func drawRect(dirtyRect: NSRect) {
        let context: CGContext! = NSGraphicsContext.currentContext()?.CGContext
        for c in calipers {
            c.drawWithContext(context, inRect: dirtyRect)
        }
    }

}

