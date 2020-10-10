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
    func showMessageWithoutSaving(_ message: String)
    func showMessageAndSaveLast(_ message: String)
    func clearMessage()
    func restoreLastMessage()
    func resetTouchBar()
}


class CalipersView: NSView {

    weak var imageView: IKImageView? = nil
    weak var scrollView: NSScrollView? = nil
    var calipersMode = false
    var calipers: [Caliper] = []
    var lockedMode = false
    var selectedCaliper: Caliper? = nil
    var mouseWasDragged = false
    var bar1Selected = false
    var bar2Selected = false
    var crossBarSelected = false
    // references to MainWindowController calibrations
    let horizontalCalibration = Calibration()
    let verticalCalibration = Calibration()

    // FIXME: weak var?
    var delegate: CalipersViewDelegate? = nil;
    
    // for color and tweak menu
    var chosenCaliper: Caliper? = nil
    
    var isTweakingComponent = false {
        didSet {
            delegate?.resetTouchBar()
        }
    }
    let tweakDistance: CGFloat = 0.2
    // distance below will allow hundredths of point precision
    let hiresTweakDistance: CGFloat = 0.01

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
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(NSResponder.deleteBackward(_:)) {
            return !noCaliperIsSelected()
        }
        if menuItem.action == #selector(colorCaliper(_:)) || menuItem.action == #selector(tweakCaliper(_:)) {
            return chosenCaliper != nil
        }
        if menuItem.action == #selector(marchCaliper(_:)) {
            return chosenCaliper != nil && (chosenCaliper?.isTimeCaliper())!
        }
        return true;
    }
        
    override func mouseDown(with theEvent: NSEvent) {
        // FIXME: do this?  Leave room for scrollbars
        var location = theEvent.locationInWindow
        selectedCaliper = getSelectedCaliper(location)
        if selectedCaliper != nil {
            if selectedCaliper!.pointNearCrossBar(location) {
                crossBarSelected = true
            }
            else if selectedCaliper!.pointNearBar1(p: location) {
                bar1Selected = true
            }
            else if selectedCaliper!.pointNearBar2(p: location) {
                bar2Selected = true
            }
        }
        else {
            imageView!.mouseDown(with: theEvent)
        }
    }

    func clearChosenComponents(exceptFor caliper: Caliper?) {
        if let caliper = caliper {
            for c in calipers {
                if c != caliper {
                    c.chosenComponent = .noComponent
                }
            }
        }
        else {
            clearAllChosenComponents()
        }
    }

    func clearAllChosenComponents() {
        for c in calipers {
            c.chosenComponent = .noComponent
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        chosenCaliper = getSelectedCaliper(event.locationInWindow)
        chosenCaliper?.chosenComponent = chosenCaliper?.getSelectedCaliperComponent(atPoint: event.locationInWindow) ?? .noComponent
        if chosenCaliper == nil && isTweakingComponent {
            isTweakingComponent = false
            delegate?.restoreLastMessage()
            stopTweaking()
        }
        // only show menu if not in middle of tweaking
        if !isTweakingComponent {
            let theMenu = NSMenu()
            let colorMenuItem = NSMenuItem(title: NSLocalizedString("Caliper Color", comment:""), action: #selector(colorCaliper(_:)), keyEquivalent: "")
            let tweakMenuItem = NSMenuItem(title: NSLocalizedString("Tweak Caliper Position", comment:""), action: #selector(tweakCaliper(_:)), keyEquivalent: "")
            let marchMenuItem = NSMenuItem(title: NSLocalizedString("Marching Caliper", comment:""), action:#selector(marchCaliper(_:)), keyEquivalent:"")
            if let chosenCaliper = chosenCaliper {
                // It should not be possible to set isMarching on a non-time caliper,
                // but will leave in this check anyway.
                if chosenCaliper.isMarching && chosenCaliper.isTimeCaliper() {
                    marchMenuItem.state = .on
                }
                if !chosenCaliper.isTimeCaliper() {
                    marchMenuItem.isEnabled = false
                }
            }
            else {
                // If you don't click near a caliper, all is disabled.
                colorMenuItem.isEnabled = false
                tweakMenuItem.isEnabled = false
                marchMenuItem.isEnabled = false
            }
            // autoenablesItems must be false or items never disabled
            theMenu.autoenablesItems = false
            theMenu.addItem(colorMenuItem)
            theMenu.addItem(tweakMenuItem)
            theMenu.addItem(marchMenuItem)
            NSMenu.popUpContextMenu(theMenu, with: event, for: self)
        }
        else {
            tweakCaliper(self)
        }
        needsDisplay = true
    }

    // This allows pinch to zoom to work.
    override func magnify(with theEvent: NSEvent) {
        NSLog("magnify")
        if !lockedMode {
            scrollView!.magnify(with: theEvent)
            updateCalibration()
        }
    }

    func vitalSigns() {
        NSLog("imageView zoom factor = %f", imageView!.zoomFactor)
        NSLog("scrollView magnify = %f", scrollView!.magnification)
        NSLog("======================")
        NSLog("documentViewSize width = %f, height = %f", scrollView!.documentView!.frame.size.width, scrollView!.documentView!.frame.size.height)
        NSLog("imageView.frame.size = %f, %f", imageView!.frame.width, imageView!.frame.height)
        NSLog("======================")
        NSLog("calipersView.frame.size = %f, %f", frame.width, frame.height)
        NSLog("contentViewSize width = %f, height = %f", scrollView!.contentView.frame.width, scrollView!.contentView.frame.height)
        NSLog("scrollView.documentVisibileRect.size = %f, %f", scrollView!.documentVisibleRect.width, scrollView!.documentVisibleRect.height)
        NSLog("window.frame.size = %f, %f", window!.frame.width, window!.frame.height)
        NSLog("======================")
        NSLog("scrollView.documentVisibleRect.origin = %f, %f", scrollView!.documentVisibleRect.origin.x, scrollView!.documentVisibleRect.origin.y)
        NSLog("======================")
        NSLog("documentViewSize - documentVisibleRectSize = %f, %f",
              scrollView!.documentView!.frame.size.width - scrollView!.documentVisibleRect.width,
              scrollView!.documentView!.frame.size.height - scrollView!.documentVisibleRect.height)
    }
    
    override func scrollWheel(with event: NSEvent) {
        if !lockedMode {
            super.scrollWheel(with: event)
        }
    }

//    func updateCalibration(offset: CGPoint) {
//        if horizontalCalibration.calibrated || verticalCalibration.calibrated {
//            horizontalCalibration.currentZoom = Double(imageView!.zoomFactor)
//            verticalCalibration.currentZoom = Double(imageView!.zoomFactor)
//            horizontalCalibration.offset = offset
//            verticalCalibration.offset = offset
//            if calipers.count > 0 {
//                needsDisplay = true
//            }
//        }
//    }

    func getOffset() -> CGPoint {
        guard let scrollView = scrollView else { return CGPoint() }
        var x = scrollView.documentVisibleRect.origin.x
        var y = scrollView.documentVisibleRect.origin.y
        // Cannot test for == 0 here, since floating point comparison isn't exact.
        if scrollView.documentView!.frame.size.width < scrollView.documentVisibleRect.width {
//        if scrollView.documentVisibleRect.origin.x < 0.01  {
            x = (scrollView.documentView!.frame.size.width - scrollView.documentVisibleRect.width) / 2
        }
        if scrollView.documentView!.frame.size.height < scrollView.documentVisibleRect.height {
//        if scrollView.documentVisibleRect.origin.y < 0.01 {
            y = (scrollView.documentView!.frame.size.height - scrollView.documentVisibleRect.height) / 2
        }
        return CGPoint(x: x, y: y)
    }

    func updateCalibration() {
        horizontalCalibration.currentZoom = Double(scrollView!.magnification)
        verticalCalibration.currentZoom = Double(scrollView!.magnification)
        horizontalCalibration.offset = getOffset()
        verticalCalibration.offset = getOffset()
        if calipers.count > 0 {
            needsDisplay = true
        }
    }
    
    @objc func marchCaliper(_ sender: AnyObject) {
        guard let chosenCaliper = chosenCaliper else { return }
        // only time calipers can march, ignore others
        guard chosenCaliper.isTimeCaliper() else { return }
        chosenCaliper.isMarching = !chosenCaliper.isMarching
        stopTweaking()
        needsDisplay = true
    }
    
    @objc func colorCaliper(_ sender: AnyObject) {
        guard let chosenCaliper = chosenCaliper else {
            return
        }
        let colorChooser: NSColorPanel = NSColorPanel.shared
        colorChooser.setTarget(self)
        colorChooser.setAction(#selector(setChoosenCaliperColor(_:)))
        colorChooser.makeKeyAndOrderFront(self)
        colorChooser.isContinuous = true
        chosenCaliper.selected = false
        self.needsDisplay = true
        colorChooser.color = chosenCaliper.color
    }

    @objc func setChoosenCaliperColor(_ sender: AnyObject) {
        let colorChooser: NSColorPanel = NSColorPanel.shared
        chosenCaliper?.color = colorChooser.color
        chosenCaliper?.unselectedColor = colorChooser.color
        self.needsDisplay = true
    }
    
    @objc func tweakCaliper(_ sender: AnyObject) {
        delegate?.resetTouchBar()
        chosenCaliper?.isTweaking = true
        clearChosenComponents(exceptFor: chosenCaliper)
        if let componentName = Caliper.componentName(chosenCaliper?.chosenComponent ?? .noComponent) {
            let message = String(format: NSLocalizedString("Tweak %@ with arrow keys and ⌘-arrow keys.  Press Escape (esc) to stop tweaking.", comment:""), componentName)
            if !isTweakingComponent {
                delegate?.showMessageAndSaveLast(message)
                isTweakingComponent = true
            }
            else {
                // showTweakMessage doesn't overwrite last message
                delegate?.showMessageWithoutSaving(message)
            }
        }
        else {
            delegate?.clearMessage()
        }
        // calipersView must be first responder, or keys down't work
        window?.makeFirstResponder(self)
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
            if !mouseWasDragged {
                if theEvent.clickCount == 1 {
                    toggleCaliperState()
                }
                else {  // at least double click
                    for c in calipers {
                        if c == selectedCaliper {
                            calipers.remove(at: calipers.firstIndex(of: c)!)
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

    func noTimeCaliperIsSelected() -> Bool {
        var noneSelected = true
        for c in calipers {
            if c.selected && c.isTimeCaliper() {
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

    // Arrow keys, up, down, right, and left for gross movements
    override func moveUp(_ sender: Any?) {
        moveChosenComponent(movementDirection: .up, distance: tweakDistance)
    }
    
    override func moveDown(_ sender: Any?) {
        moveChosenComponent(movementDirection: .down, distance: tweakDistance)
    }
    
    override func moveLeft(_ sender: Any?) {
        moveChosenComponent(movementDirection: .left, distance: tweakDistance)
    }
    
    override func moveRight(_ sender: Any?) {
        moveChosenComponent(movementDirection: .right, distance: tweakDistance)
    }

    // Command + arrow keys for very fine movements
    override func moveToEndOfLine(_ sender: Any?) {
        moveChosenComponent(movementDirection: .right, distance: hiresTweakDistance)
    }
    
    override func moveToBeginningOfLine(_ sender: Any?) {
        moveChosenComponent(movementDirection: .left, distance: hiresTweakDistance)
    }

    override func moveToBeginningOfDocument(_ sender: Any?) {
        moveChosenComponent(movementDirection: .up, distance: hiresTweakDistance)
    }

    override func moveToEndOfDocument(_ sender: Any?) {
        moveChosenComponent(movementDirection: .down, distance: hiresTweakDistance)
    }

    override func cancelOperation(_ sender: Any?) {
        stopTweaking()
    }
    
    func stopTweaking() {
        delegate?.resetTouchBar()
        clearAllChosenComponents()
        if (chosenCaliper == nil) {
            needsDisplay = true
            return
        }
        chosenCaliper?.isTweaking = false
        chosenCaliper = nil
        isTweakingComponent = false
        delegate?.restoreLastMessage()
        needsDisplay = true
    }
    
    override func deleteBackward(_ sender: Any?) {
        for c in calipers {
            if c.selected {
                calipers.remove(at: calipers.firstIndex(of: c)!)
                needsDisplay = true
            }
        }
    }
    
    func deleteAllCalipers() {
        calipers.removeAll()
        needsDisplay = true
    }
    
    func moveChosenComponent(movementDirection: MovementDirection, distance: CGFloat) {
        if let c = chosenCaliper {
            if isTweakingComponent {
                c.moveBarInDirection(movementDirection: movementDirection, distance: distance)
                needsDisplay = true
            }
        }
    }
    
    func updateCaliperPreferences(_ unselectedColor: NSColor?, selectedColor: NSColor?, lineWidth: Int, rounding: Rounding, autoPositionText: Bool, timeCaliperTextPosition: TextPosition, amplitudeCaliperTextPosition: TextPosition) {
         for c in calipers {
            // we no longer set c.unselected color to the default.  Calipers keep their colors, only
            // new calipers get the default color
            if let color = selectedColor {
                c.selectedColor = color
            }
            if c.selected {
                c.color = c.selectedColor
            }
            c.lineWidth = CGFloat(lineWidth)
            c.rounding = rounding
            c.autoPositionText = autoPositionText
            if c.direction == .horizontal {
                c.textPosition = timeCaliperTextPosition
            }
            else if c.direction == .vertical {
                c.textPosition = amplitudeCaliperTextPosition
            }
        }
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let context = (NSGraphicsContext.current?.cgContext)!
        for c in calipers {
            c.drawWithContext(context, inRect: dirtyRect)
        }
    }

    func caliper0Bar1Position() -> CGFloat? {
        if calipers.count > 0 {
            return calipers[0].bar1Position
        }
        return nil
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

