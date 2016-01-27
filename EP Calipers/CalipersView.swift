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
    // references to MainWindowController calibrations
    let horizontalCalibration = Calibration()
    let verticalCalibration = Calibration()

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
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        if menuItem.action == Selector("deleteBackward:") {
            return !locked
        }
        return true
    }
    

    
    override func mouseDown(theEvent: NSEvent) {
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
    
    override func magnifyWithEvent(theEvent: NSEvent) {
        if !lockedMode {
            imageView!.magnifyWithEvent(theEvent)
        }
        updateCalibration()
    }
    
    func updateCalibration() {
        if horizontalCalibration.calibrated || verticalCalibration.calibrated {
            horizontalCalibration.currentZoom = Double(imageView!.zoomFactor)
            verticalCalibration.currentZoom = Double(imageView!.zoomFactor)
        }
        if calipers.count > 0 {
            needsDisplay = true
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
        if selectedCaliper != nil {
            if !mouseWasDragged && !locked {
                if theEvent.clickCount == 1 {
                    toggleCaliperState()
                }
                else {  // at least double click
                    for c in calipers {
                        if c == selectedCaliper {
                            calipers.removeAtIndex(calipers.indexOf(c)!)
                        }
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
            unselectCalipersExcept(c)
        }
    }
    
    func unselectCalipersExcept(c: Caliper) {
        for cal in calipers {
            if cal != c {
                unselectCaliper(cal)
            }
        }
    }
    
    func noCaliperIsSelected() -> Bool {
        var noneSelected = true
        for c in calipers {
            if c.selected {
                noneSelected = false
            }
        }
        return noneSelected
    }
    
    func activeCaliper() -> Caliper? {
        if calipers.count <= 0 {
            return nil
        }
        var caliper: Caliper? = nil
        for c in calipers {
            if c.selected {
                caliper = c
            }
        }
        return caliper
    }
    
    // TODO: may not need this is menu option available instead
    override func keyDown(theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }
    
    
    override func deleteBackward(sender: AnyObject?) {
        if locked {
            return
        }
        for c in calipers {
            if c.selected {
                calipers.removeAtIndex(calipers.indexOf(c)!)
                needsDisplay = true
            }
        }
    }
    
    func updateCaliperColors(unselectedColor: NSColor?, selectedColor: NSColor?, lineWidth: Int) {
         for c in calipers {
            if let color = unselectedColor {
                c.unselectedColor = color
            }
            if let color = selectedColor {
                c.selectedColor = color
            }
            if c.selected {
                c.color = c.selectedColor
            }
            else {
                c.color = c.unselectedColor
            }
            c.lineWidth = CGFloat(lineWidth)
        }
        needsDisplay = true
    }
    
    override func drawRect(dirtyRect: NSRect) {
        let context: CGContext! = NSGraphicsContext.currentContext()?.CGContext
        for c in calipers {
            c.drawWithContext(context, inRect: dirtyRect)
        }
    }
    
    func takeScreenshot() -> Bool {
        // Takes screenshot and stores in sandbox data directory (or home directory if
        // no sandbox.  Returns false if screencapture doesn't work for some reason.
        // Screencapture in preview mode and window mode with sound.
        let prefix = "EPCalipers"
        let guid = NSProcessInfo.processInfo().globallyUniqueString
        let fileName = "\(prefix)_\(guid)"
        let path = "\(NSHomeDirectory())/\(fileName).png"
        NSLog("path = \(path)")
        let result = system("screencapture -P -w \(path)")
        if result != 0 {
            NSLog("System error = \(result)")
            return false
        }
        return true
    }

// MARK: functions below were attempt at saving and printing without using screencapture -- abandoned for now
    
//    @IBAction override func print(sender: AnyObject?) {
//        NSLog("printing it")
//        let rect = convertRect(bounds, toView: nil)
//        NSLog("Frame relative to window = \(rect)")
//        if let screenRect = window?.convertRectToScreen(rect) {
//            NSLog("Frame relative to screen = \(screenRect)")
//        }
//        // TODO: change back
//        return
////        printMergedImage()
//    }
//    
// Print has problem because of multiple NSViews, first responder changes
//    // see http://findnerd.com/list/view/How-to-print-an-NSImage/755/
//    func printMergedImage() {
//        NSLog("Print")
//        let image: NSImage = NSImage(CGImage: mergedImage()!, size: imageView!.bounds.size)
//        let printImageView = NSImageView()
//        printImageView.frame = NSMakeRect(0, 0, image.size.width, image.size.height)
//        printImageView.image = image
//        let printInfo: NSPrintInfo = NSPrintInfo.sharedPrintInfo()
//        printInfo.horizontalPagination = .FitPagination
//        printInfo.verticalPagination = .FitPagination
//        NSPrintOperation(view: printImageView, printInfo: printInfo).runOperation()
//    }
    
//    // see http://stackoverflow.com/questions/18583465/merging-stacking-two-images-with-cocoa-osx
//    func mergedImage() -> CGImage? {
//        return imageFromScreen()
////        let overlay: NSImage = NSImage(data: dataWithPDFInsideRect(bounds))!
////        let background: NSImage = NSImage(CGImage: imageView!.image().takeUnretainedValue(), size: imageView!.bounds.size)
////        
////        let newImage: NSImage = NSImage(size: background.size)
////        newImage.lockFocus()
////        
////        var newImageRect = CGRectZero
////        newImageRect.size = newImage.size
////        
////        background.drawInRect(newImageRect)
////        overlay.drawInRect(newImageRect)
////        
////        newImage.unlockFocus()
////        
////        let newImageRef = newImage.CGImageForProposedRect(nil , context: nil, hints: nil)
////        return newImageRef
//    }
    
    

//    func imageFromScreen() -> CGImage? {
//        // capture to clipboard, no sound
//        let result = system("screencapture -c -x")
//        if result != 0 {
//            NSLog("System error = \(result)")
//            return nil
//        }
//        if let imageFromClipBoard = NSImage(pasteboard: NSPasteboard.generalPasteboard()) {
//            if let screenshotImage: CGImageRef = (imageFromClipBoard.CGImageForProposedRect(nil, context: nil, hints: nil)) {
//                let rect = convertRect(bounds, toView: nil)
//                let screenRect = window!.convertRectToScreen(rect)
//                let screenshotCropped = CGImageCreateWithImageInRect(screenshotImage, screenRect)
//
//                return screenshotCropped
//            }
//            else {
//                return nil
//            }
//        }
//        else {
//            return nil
//        }
//        
//    }

}

