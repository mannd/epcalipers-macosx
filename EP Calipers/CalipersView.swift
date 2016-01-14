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

    // temporary preferences
    struct EPCPreferences {
        static var singleClickMode: Bool = true
    }
    
    var imageView: IKImageView? = nil
    var calipersMode = false
    var calipers: [Caliper] = []
    var lockedMode = false
    // not sure if still need this
    var locked = false
    var selectedCaliper: Caliper? = nil
    var mouseWasDragged = false

    // needed to handle key input
    override var acceptsFirstResponder: Bool {
        return true }
    

    // used to hold statics for mouse dragging
    struct Holder {
        static var bar1Selected = false
        static var bar2Selected = false
        static var crossBarSelected = false
    }

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
//        acceptsFirstResponder = true
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
    
    
    
//    @IBAction func setRotation(sender: AnyObject) {
//        NSLog("SetRotation")
////        imageView!.setRotation(sender)
//    }
//
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

    override func magnifyWithEvent(theEvent: NSEvent) {
        NSLog("Magnify event")
        if !lockedMode {
            imageView!.magnifyWithEvent(theEvent)
        }
        NSLog("Zoom factor = %f", imageView!.zoomFactor)
    }
    
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
            if selectedCaliper!.pointNearCrossBar(theEvent.locationInWindow) {
                Holder.crossBarSelected = true
            }
            else if selectedCaliper!.pointNearBar(theEvent.locationInWindow, forBarPosition: selectedCaliper!.bar1Position) {
                Holder.bar1Selected = true
            }
            else if selectedCaliper!.pointNearBar(theEvent.locationInWindow, forBarPosition: selectedCaliper!.bar2Position) {
                Holder.bar2Selected = true
            }
        }
        else {
            imageView!.mouseDown(theEvent)
        }
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        NSLog("MouseDragged")
        if let c = selectedCaliper {
            var delta = CGPoint(x: theEvent.deltaX, y: theEvent.deltaY)
            if c.direction == .Vertical {
                let tmp = delta.x
                delta.x = delta.y
                delta.y = tmp
            }
            if Holder.crossBarSelected {
                c.bar1Position += delta.x
                c.bar2Position += delta.x
                // origin is lower left in Cocoa
                c.crossBarPosition -= delta.y
            }
            else if Holder.bar1Selected {
                c.bar1Position += delta.x
            }
            else if Holder.bar2Selected {
                c.bar2Position += delta.x
            }
            mouseWasDragged = true
            needsDisplay = true
        }
        else {
            imageView!.mouseDragged(theEvent)
        }
    }
    
    // double click to toggle selected state
    override func mouseUp(theEvent: NSEvent) {
        NSLog("MouseUp")
        if selectedCaliper != nil {
            if EPCPreferences.singleClickMode {
                if theEvent.clickCount == 1 && !mouseWasDragged {
                    toggleCaliperState()
                }
                else {
                    for c in calipers {
                        if c.selected {
                            calipers.removeAtIndex(calipers.indexOf(c)!)
                            needsDisplay = true
                        }
                    }
                }
            }
            else if theEvent.clickCount > 1 {
                toggleCaliperState()
            }
            selectedCaliper = nil
            mouseWasDragged = false
            Holder.bar1Selected = false
            Holder.bar2Selected = false
            Holder.crossBarSelected = false
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
        }
    }
    
    override func keyDown(theEvent: NSEvent) {
        NSLog("Key down")
        interpretKeyEvents([theEvent])
    }
    
    
    override func deleteBackward(sender: AnyObject?) {
        NSLog("Delete")
        for c in calipers {
            if c.selected {
                calipers.removeAtIndex(calipers.indexOf(c)!)
                needsDisplay = true
            }
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        let context: CGContext! = NSGraphicsContext.currentContext()?.CGContext
        for c in calipers {
            c.drawWithContext(context, inRect: dirtyRect)
        }
    }

}

