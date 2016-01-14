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
    var bar1Selected = false
    var bar2Selected = false
    var crossBarSelected = false

    // needed to handle key input
    override var acceptsFirstResponder: Bool {
        return true }
    
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
        selectedCaliper = getSelectedCaliper(theEvent.locationInWindow)
        if selectedCaliper != nil {
            if selectedCaliper!.pointNearCrossBar(theEvent.locationInWindow) {
                crossBarSelected = true
            }
            else if selectedCaliper!.pointNearBar(theEvent.locationInWindow, forBarPosition: selectedCaliper!.bar1Position) {
                bar1Selected = true
            }
            else if selectedCaliper!.pointNearBar(theEvent.locationInWindow, forBarPosition: selectedCaliper!.bar2Position) {
                bar2Selected = true
            }
        }
        else {
            imageView!.mouseDown(theEvent)
        }
    }
    
    func getSelectedCaliper(point: CGPoint) -> Caliper?{
        var caliper: Caliper? = nil
        for c in calipers {
            if c.pointNearCaliper(point) && caliper == nil {
                caliper = c
            }
        }
        return caliper
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        // NSLog("MouseDragged")
        if let c = selectedCaliper {
            var delta = CGPoint(x: theEvent.deltaX, y: theEvent.deltaY)
            if c.direction == .Vertical {
                // different from iOS because origin at lower left
                let tmp = delta.x
                delta.x = -delta.y
                delta.y = -tmp
            }
            if crossBarSelected {
                c.bar1Position += delta.x
                c.bar2Position += delta.x
                // origin is lower left in Cocoa
                c.crossBarPosition -= delta.y
            }
            else if bar1Selected {
                c.bar1Position += delta.x
            }
            else if bar2Selected {
                c.bar2Position += delta.x
            }
            mouseWasDragged = true
            needsDisplay = true
        }
        else {
            imageView!.mouseDragged(theEvent)
        }
    }
    
    // TODO: consider context menu or options for other action with double click, 
    // e.g. calibrate
    override func mouseUp(theEvent: NSEvent) {
        NSLog("MouseUp")
        if selectedCaliper != nil {
            if theEvent.clickCount == 1 && !mouseWasDragged {
                toggleCaliperState()
            }
            else {  // at least double click
                for c in calipers {
                    if c.selected {
                        calipers.removeAtIndex(calipers.indexOf(c)!)
                        needsDisplay = true
                    }
                }
            }
            selectedCaliper = nil
            mouseWasDragged = false
            bar1Selected = false
            bar2Selected = false
            crossBarSelected = false
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
    
    // TODO: may not need this is menu option available instead
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

