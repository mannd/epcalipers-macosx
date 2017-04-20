//
//  CalipersView.swift
//  EP Calipers
//
//  Created by David Mann on 1/3/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa
import Quartz

protocol CalipersViewDelegate {
    func showMessage(_ message: String)
    func clearMessage()
    func restoreLastMessage()
}


class CalipersView: NSView {

    var imageView: FixedIKImageView? = nil
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
    
    var delegate: CalipersViewDelegate? = nil;
    
    // for color and tweak menu
    var chosenCaliper: Caliper? = nil
    var chosenComponent: CaliperComponent = .noComponent

    // needed to handle key input
    override var acceptsFirstResponder: Bool {
        return true }
    

    func selectCaliper(_ c: Caliper) {
        c.color = c.selectedColor
        c.selected = true
        needsDisplay = true
    }
    
    func unselectCaliper(_ c: Caliper) {
        c.color = c.unselectedColor
        c.selected = false
        needsDisplay = true
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(NSResponder.deleteBackward(_:)) {
            return !locked
        }
        if menuItem.action == #selector(colorCaliper(_:)) || menuItem.action == #selector(tweakCaliper(_:)) {
            return chosenCaliper != nil
        }
        return true;
    }
        
    override func mouseDown(with theEvent: NSEvent) {
        selectedCaliper = getSelectedCaliper(theEvent.locationInWindow)
        if selectedCaliper != nil {
            if selectedCaliper!.pointNearCrossBar(theEvent.locationInWindow) {
                crossBarSelected = true
            }
            else if selectedCaliper!.pointNearBar1(p: theEvent.locationInWindow) {
                bar1Selected = true
            }
            else if selectedCaliper!.pointNearBar2(p: theEvent.locationInWindow) {
                bar2Selected = true
            }
        }
        else {
            imageView!.mouseDown(with: theEvent)
        }
    }
    

    
    override func rightMouseDown(with event: NSEvent) {
        NSLog("right mouse down")
        chosenCaliper = getSelectedCaliper(event.locationInWindow)
        chosenComponent = getSelectedCaliperComponent(forCaliper: chosenCaliper, atPoint: event.locationInWindow)
        if chosenCaliper == nil {
            chosenComponent = .noComponent
            delegate?.restoreLastMessage()
        }
        let theMenu = NSMenu()
        let colorMenuItem = NSMenuItem(title: "Color Caliper", action: #selector(colorCaliper(_:)), keyEquivalent: "")
        let tweakMenuItem = NSMenuItem(title: "Tweak Caliper Position", action: #selector(tweakCaliper(_:)), keyEquivalent: "")
        theMenu.addItem(colorMenuItem)
        theMenu.addItem(tweakMenuItem)
        NSMenu.popUpContextMenu(theMenu, with: event, for: self)
        
    }
    
    override func magnify(with theEvent: NSEvent) {
        if !lockedMode {
            imageView!.magnify(with: theEvent)
            updateCalibration()
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        if !lockedMode {
            super.scrollWheel(with: event)
        }
    }
    
    func updateCalibration() {
        if horizontalCalibration.calibrated || verticalCalibration.calibrated {
            horizontalCalibration.currentZoom = Double(imageView!.zoomFactor)
            verticalCalibration.currentZoom = Double(imageView!.zoomFactor)
            if calipers.count > 0 {
                needsDisplay = true
            }
        }
    }
    
    func colorCaliper(_ sender: AnyObject) {
        guard let chosenCaliper = chosenCaliper else {
            return;
        }
        let colorChooser: NSColorPanel = NSColorPanel.shared()
        colorChooser.setTarget(self)
        colorChooser.setAction(#selector(setChoosenCaliperColor(_:)))
        colorChooser.makeKeyAndOrderFront(self)
        colorChooser.isContinuous = true
        chosenCaliper.selected = false
        self.needsDisplay = true
        colorChooser.color = chosenCaliper.color
    }

    func setChoosenCaliperColor(_ sender: AnyObject) {
        NSLog("Color changed")
        let colorChooser: NSColorPanel = NSColorPanel.shared()
        chosenCaliper?.color = colorChooser.color
        chosenCaliper?.unselectedColor = colorChooser.color
        self.needsDisplay = true
    }
    
    func tweakCaliper(_ sender: AnyObject) {
        if let componentName = Caliper.componentName(chosenComponent) {
            delegate?.showMessage("Tweak " + componentName + " with arrow keys or alt-arrow keys.  Press Escape to exit.")
        }
        else {
            delegate?.clearMessage()
        }
    }
    
    func getSelectedCaliperComponent(forCaliper c: Caliper?, atPoint p: NSPoint) -> CaliperComponent {
        guard let c = c else {
            return .noComponent
        }
        if c.pointNearBar1(p: p) {
            return c.direction == .horizontal ? .leftBar : .lowerBar
        }
        else if c.pointNearBar2(p: p) {
            return c.direction == .horizontal ? .rightBar : .upperBar
        }
        else if c.pointNearCrossBar(p) {
            return c.isAngleCaliper ? .apex : .crossBar
        }
        else {
            return .noComponent
        }
        
    }
    

    
    func getSelectedCaliper(_ point: CGPoint) -> Caliper?{
        var caliper: Caliper? = nil
        for c in calipers {
            if c.pointNearCaliper(point) && caliper == nil {
                caliper = c
            }
        }
        return caliper
    }
    
    override func mouseDragged(with theEvent: NSEvent) {
        if let c = selectedCaliper {
            var delta = CGPoint(x: theEvent.deltaX, y: theEvent.deltaY)
            let location = theEvent.locationInWindow
            if c.direction == .vertical {
                // different from iOS because origin at lower left
                let tmp = delta.x
                delta.x = -delta.y
                delta.y = -tmp
            }
            if crossBarSelected {
                c.moveCrossBar(delta: delta)
            }
            else if bar1Selected {
                c.moveBar1(delta: delta, forLocation: location)
            }
            else if bar2Selected {
                c.moveBar2(delta: delta, forLocation: location)
            }
            mouseWasDragged = true
            needsDisplay = true
        }
        else {
            imageView!.mouseDragged(with: theEvent)
        }
    }
    
    override func mouseUp(with theEvent: NSEvent) {
        if selectedCaliper != nil {
            if !mouseWasDragged && !locked {
                if theEvent.clickCount == 1 {
                    toggleCaliperState()
                }
                else {  // at least double click
                    for c in calipers {
                        if c == selectedCaliper {
                            calipers.remove(at: calipers.index(of: c)!)
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
            imageView!.mouseUp(with: theEvent)
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
    
    func unselectCalipersExcept(_ c: Caliper) {
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
    
    override func keyDown(with theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }
    
    override func moveUp(_ sender: Any?) {
        NSLog("Up arrow.")
    }
    
    override func moveDown(_ sender: Any?) {
        NSLog("Down arrow")
    }
    
    override func moveLeft(_ sender: Any?) {
        if (chosenCaliper == nil) {
            return
        }
        NSLog("Left arrow")
        chosenCaliper?.moveBarInDirection(direction: .left, distance: 0.1, forComponent: chosenComponent)
        needsDisplay = true
    }
    
    override func moveRight(_ sender: Any?) {
        if (chosenCaliper == nil) {
            return
        }
        NSLog("Right arrow")
        chosenCaliper?.moveBarInDirection(direction: .right, distance: 0.1, forComponent: chosenComponent)
        needsDisplay = true
    }
    
    override func cancelOperation(_ sender: Any?) {
        if (chosenCaliper == nil) {
            return
        }
        NSLog("Escape")
        chosenCaliper = nil
        chosenComponent = .noComponent
        delegate?.restoreLastMessage()
    }
    
    override func deleteBackward(_ sender: Any?) {
        if locked {
            return
        }
        for c in calipers {
            if c.selected {
                calipers.remove(at: calipers.index(of: c)!)
                needsDisplay = true
            }
        }
    }
    
    // TODO: do we change all caliper colors, or just new ones?  What happens in the apps?
    func updateCaliperPreferences(_ unselectedColor: NSColor?, selectedColor: NSColor?, lineWidth: Int, roundMsecRate: Bool) {
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
            c.roundMsecRate = roundMsecRate
        }
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let context = (NSGraphicsContext.current()?.cgContext)!
        for c in calipers {
            c.drawWithContext(context, inRect: dirtyRect)
        }
    }
    
    // This doesn't work as of OS 10.12.  Less need for screenshots now that transparent windows are possible.
    func takeScreenshot() -> Bool {
        // Takes screenshot and stores in sandbox data directory (or home directory if
        // no sandbox.  Returns false if screencapture doesn't work for some reason or
        // if escape used to cancel screencapture.
        // Screencapture in preview mode and window mode with sound.
        let prefix = "EPCalipers"
        let guid = ProcessInfo.processInfo.globallyUniqueString
        let fileName = "\(prefix)_\(guid)"
        let path = "\(NSHomeDirectory())/\(fileName).png"
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["screencapture -P -w \(path)"]
        task.launch()
        
//        let result = system("screencapture -P -w \(path)")
//        if result != 0 {
//            return false
//        }
        return true
    }

}

