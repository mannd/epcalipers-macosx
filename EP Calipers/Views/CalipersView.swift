//
//  CalipersView.swift
//  EP Calipers
//
//  Created by David Mann on 1/3/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa
import Quartz

protocol CalipersViewDelegate: AnyObject {
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
    var isTransparent = false
    var selectedCaliper: Caliper? = nil
    var mouseWasDragged = false
    var bar1Selected = false
    var bar2Selected = false
    var crossBarSelected = false
    private var lastContextMenuLocation: NSPoint?
    private final class NoteContainerView: NSView, NSTextViewDelegate {
        private var trackingArea: NSTrackingArea?
        private var showBorder = false
        private var isHovering = false
        private var isEditing = false
        private var isSelected = false
        private let hitSlop: CGFloat
        weak var textView: NSTextView?

        init(frame frameRect: NSRect, hitSlop: CGFloat) {
            self.hitSlop = hitSlop
            super.init(frame: frameRect)
        }

        required init?(coder: NSCoder) {
            return nil
        }

        override var isFlipped: Bool { true }

        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            NSColor.clear.setFill()
            dirtyRect.fill()
            if showBorder {
                NSColor.black.setStroke()
                let path = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
                path.lineWidth = 1.0
                path.stroke()
            }
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let trackingArea = trackingArea {
                removeTrackingArea(trackingArea)
            }
            let trackingRect = bounds.insetBy(dx: -hitSlop, dy: -hitSlop)
            let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow]
            let area = NSTrackingArea(rect: trackingRect, options: options, owner: self, userInfo: nil)
            addTrackingArea(area)
            trackingArea = area
        }

        override func mouseEntered(with event: NSEvent) {
            isHovering = true
            updateBorderVisibility()
        }

        override func mouseExited(with event: NSEvent) {
            isHovering = false
            updateBorderVisibility()
        }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
            updateBorderVisibility()
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
            isSelected = false
            updateBorderVisibility()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            isSelected = window?.firstResponder === textView
            updateBorderVisibility()
        }

        private func updateBorderVisibility() {
            showBorder = isHovering || isEditing || isSelected
            needsDisplay = true
        }

        var isBorderVisible: Bool {
            return showBorder
        }
    }

    private final class NoteDragHandleView: NSView {
        weak var owner: CalipersView?
        weak var noteView: NoteContainerView?
        private let hitSlop: CGFloat
        private var lastDragLocation: NSPoint?

        init(frame frameRect: NSRect, hitSlop: CGFloat) {
            self.hitSlop = hitSlop
            super.init(frame: frameRect)
        }

        required init?(coder: NSCoder) {
            return nil
        }

        override var isFlipped: Bool { true }

        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let noteView = noteView, noteView.isBorderVisible else {
                return nil
            }
            let innerRect = bounds.insetBy(dx: hitSlop, dy: hitSlop)
            if innerRect.contains(point) {
                return nil
            }
            return self
        }

        override func mouseDown(with event: NSEvent) {
            owner?.window?.makeFirstResponder(owner)
            lastDragLocation = owner?.convert(event.locationInWindow, from: nil)
        }

        override func mouseDragged(with event: NSEvent) {
            guard let owner = owner else { return }
            let currentLocation = owner.convert(event.locationInWindow, from: nil)
            if let lastLocation = lastDragLocation {
                let delta = NSPoint(x: currentLocation.x - lastLocation.x, y: currentLocation.y - lastLocation.y)
                owner.moveNote(for: noteView, byScaledDelta: delta)
            }
            lastDragLocation = currentLocation
        }

        override func mouseUp(with event: NSEvent) {
            lastDragLocation = nil
        }
    }

    private struct NoteEntry {
        var view: NoteContainerView
        var dragHandle: NoteDragHandleView?
        var absoluteAnchor: NSPoint
    }
    private var noteEntries: [NoteEntry] = []
    private let defaultNoteSize = NSSize(width: 180, height: 80)
    private let noteHitSlop: CGFloat = 10.0
    private let defaultNoteFontSize = NSFont.systemFontSize
    private let defaultCaliperFontSize: CGFloat = 18.0
    private let minimumFontSize: CGFloat = 10.0
    private let maximumFontSize: CGFloat = 36.0
    var hasNotes: Bool { !noteEntries.isEmpty }
    // references to MainWindowController calibrations
    let horizontalCalibration = Calibration()
    let verticalCalibration = Calibration()

    weak var delegate: CalipersViewDelegate? = nil;
    
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
        // Ctrl-left click emulates right click.
        if theEvent.modifierFlags.contains(.control) {
            return self.rightMouseDown(with: theEvent)
        }
        let pointInView = convert(theEvent.locationInWindow, from: nil)
        if !noteContainsPoint(pointInView) {
            window?.makeFirstResponder(self)
        }
        let location = theEvent.locationInWindow
        selectedCaliper = getSelectedCaliper(location)
        if let selectedCaliper = selectedCaliper {
            if selectedCaliper.pointNearCrossBar(location) {
                crossBarSelected = true
            }
            else if selectedCaliper.pointNearBar1(p: location) {
                bar1Selected = true
            }
            else if selectedCaliper.pointNearBar2(p: location) {
                bar2Selected = true
            }
        }
        else {
            imageView?.mouseDown(with: theEvent)
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
        lastContextMenuLocation = convert(event.locationInWindow, from: nil)
        let pointInView = lastContextMenuLocation ?? .zero
        let isNearNote = nearNote(pointInView)
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
            let addNoteMenuItem = NSMenuItem(title: NSLocalizedString("Add Note", comment:""), action: #selector(addNote(_:)), keyEquivalent: "")
            let deleteNoteMenuItem = NSMenuItem(title: NSLocalizedString("Delete Note", comment:""), action: #selector(deleteNote(_:)), keyEquivalent: "")
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
            deleteNoteMenuItem.isEnabled = isNearNote
            // autoenablesItems must be false or items never disabled
            theMenu.autoenablesItems = false
            theMenu.addItem(colorMenuItem)
            theMenu.addItem(tweakMenuItem)
            theMenu.addItem(marchMenuItem)
            theMenu.addItem(addNoteMenuItem)
            theMenu.addItem(deleteNoteMenuItem)
            NSMenu.popUpContextMenu(theMenu, with: event, for: self)
        }
        else {
            tweakCaliper(self)
        }
        needsDisplay = true
    }

    // This allows pinch to zoom to work.
    override func magnify(with theEvent: NSEvent) {
        if !lockedMode {
            scrollView?.magnify(with: theEvent)
            updateCalibration()
        }
    }

    // For debugging only.
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

    func getOffset() -> CGPoint {
        guard let scrollView = scrollView, let documentView = scrollView.documentView else { return CGPoint() }
        var x = scrollView.documentVisibleRect.origin.x
        var y = scrollView.documentVisibleRect.origin.y
        if documentView.frame.size.width < scrollView.documentVisibleRect.width {
            x = (documentView.frame.size.width - scrollView.documentVisibleRect.width) / 2
        }
        if documentView.frame.size.height < scrollView.documentVisibleRect.height {
            y = (documentView.frame.size.height - scrollView.documentVisibleRect.height) / 2
        }
        return CGPoint(x: x, y: y)
    }

    func updateCalibration() {
        guard let scrollView = scrollView else { return }
        horizontalCalibration.currentZoom = Double(scrollView.magnification)
        verticalCalibration.currentZoom = Double(scrollView.magnification)
        horizontalCalibration.offset = getOffset()
        verticalCalibration.offset = getOffset()
        updateCaliperTextFontsForCurrentZoom()
        updateNoteFrames()
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

    @objc func addNote(_ sender: AnyObject) {
        let absoluteAnchor = resolveNoteAbsoluteAnchor()
        let scaledAnchor = noteAnchorInView(fromAbsoluteAnchor: absoluteAnchor)
        let scaledOrigin = noteOriginInView(fromAnchor: scaledAnchor)
        let noteFrame = NSRect(origin: scaledOrigin, size: defaultNoteSize)
        let containerView = NoteContainerView(frame: noteFrame, hitSlop: noteHitSlop)
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor

        let scrollView = NSScrollView(frame: containerView.bounds)
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.autoresizingMask = [.width, .height]

        let textView = NSTextView(frame: NSRect(origin: .zero, size: defaultNoteSize))
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textColor = .black
        textView.font = NSFont.systemFont(ofSize: noteFontSizeForCurrentZoom())
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.autoresizingMask = [.width, .height]
        textView.delegate = containerView
        containerView.textView = textView
        scrollView.documentView = textView

        containerView.addSubview(scrollView)
        addSubview(containerView)
        let handleFrame = noteFrame.insetBy(dx: -noteHitSlop, dy: -noteHitSlop)
        let dragHandle = NoteDragHandleView(frame: handleFrame, hitSlop: noteHitSlop)
        dragHandle.owner = self
        dragHandle.noteView = containerView
        addSubview(dragHandle, positioned: .below, relativeTo: containerView)
        noteEntries.append(NoteEntry(view: containerView, dragHandle: dragHandle, absoluteAnchor: absoluteAnchor))
        window?.makeFirstResponder(textView)
    }

    @objc func deleteNote(_ sender: AnyObject) {
        guard let location = lastContextMenuLocation else { return }
        guard let noteIndex = noteIndex(near: location) else { return }
        let entry = noteEntries.remove(at: noteIndex)
        entry.view.removeFromSuperview()
        entry.dragHandle?.removeFromSuperview()
        needsDisplay = true
    }

    func deleteAllNotes() {
        for entry in noteEntries {
            entry.view.removeFromSuperview()
            entry.dragHandle?.removeFromSuperview()
        }
        noteEntries.removeAll()
        needsDisplay = true
    }

    func setNotesHidden(_ hidden: Bool) {
        for entry in noteEntries {
            entry.view.isHidden = hidden
            entry.dragHandle?.isHidden = hidden
        }
    }

    private func nearNote(_ point: NSPoint) -> Bool {
        return noteIndex(near: point) != nil
    }

    private func resolveNoteAbsoluteAnchor() -> NSPoint {
        let defaultLocation = NSPoint(x: bounds.midX - defaultNoteSize.width / 2,
                                      y: bounds.midY - defaultNoteSize.height / 2)
        let rawLocation = lastContextMenuLocation ?? defaultLocation
        let anchorInView = noteAnchorInView(for: rawLocation)
        return noteAnchorInAbsoluteSpace(from: anchorInView)
    }

    private func noteAnchorInView(for rawLocation: NSPoint) -> NSPoint {
        return rawLocation
    }

    private func noteAnchorInAbsoluteSpace(from scaledAnchor: NSPoint) -> NSPoint {
        let scale = CGFloat(horizontalCalibration.currentZoom)
        let absoluteX = Position.translateToAbsolutePosition(scaledPosition: scaledAnchor.x,
                                                             offset: horizontalCalibration.offset.x,
                                                             scale: scale)
        let absoluteY = Position.translateToAbsolutePosition(scaledPosition: scaledAnchor.y,
                                                             offset: verticalCalibration.offset.y,
                                                             scale: scale)
        return NSPoint(x: absoluteX, y: absoluteY)
    }

    private func noteAnchorInView(fromAbsoluteAnchor absoluteAnchor: NSPoint) -> NSPoint {
        let scale = CGFloat(horizontalCalibration.currentZoom)
        let scaledX = Position.translateToScaledPosition(absolutePosition: absoluteAnchor.x,
                                                         offset: horizontalCalibration.offset.x,
                                                         scale: scale)
        let scaledY = Position.translateToScaledPosition(absolutePosition: absoluteAnchor.y,
                                                         offset: verticalCalibration.offset.y,
                                                         scale: scale)
        return NSPoint(x: scaledX, y: scaledY)
    }

    private func noteOriginInView(fromAnchor anchor: NSPoint) -> NSPoint {
        let yOrigin = isFlipped ? anchor.y : anchor.y - defaultNoteSize.height
        return NSPoint(x: anchor.x, y: yOrigin)
    }

    private func updateNoteFrames() {
        guard noteEntries.count > 0 else { return }
        for index in noteEntries.indices {
            let entry = noteEntries[index]
            let scaledAnchor = noteAnchorInView(fromAbsoluteAnchor: entry.absoluteAnchor)
            let scaledOrigin = noteOriginInView(fromAnchor: scaledAnchor)
            let noteFrame = NSRect(origin: scaledOrigin, size: defaultNoteSize)
            entry.view.isHidden = !bounds.contains(noteFrame)
            entry.view.setFrameOrigin(scaledOrigin)
            updateFontForNote(entry.view)
            if let dragHandle = entry.dragHandle {
                let handleFrame = noteFrame.insetBy(dx: -noteHitSlop, dy: -noteHitSlop)
                dragHandle.isHidden = entry.view.isHidden
                dragHandle.frame = handleFrame
            }
        }
    }

    private func noteFontSizeForCurrentZoom() -> CGFloat {
        let zoom = CGFloat(horizontalCalibration.currentZoom)
        let scaledSize = defaultNoteFontSize * zoom
        return max(minimumFontSize, min(maximumFontSize, scaledSize))
    }

    private func caliperFontSizeForCurrentZoom() -> CGFloat {
        let zoom = CGFloat(horizontalCalibration.currentZoom)
        let scaledSize = defaultCaliperFontSize * zoom
        return max(minimumFontSize, min(maximumFontSize, scaledSize))
    }

    private func updateCaliperTextFontsForCurrentZoom() {
        let fontSize = caliperFontSizeForCurrentZoom()
        for caliper in calipers {
            if let scaledFont = NSFont(name: caliper.textFont.fontName, size: fontSize) {
                caliper.textFont = scaledFont
            }
            else {
                caliper.textFont = NSFont.systemFont(ofSize: fontSize, weight: .medium)
            }
        }
    }

    private func updateFontForNote(_ noteView: NoteContainerView) {
        guard let textView = noteView.textView else { return }
        let font = NSFont.systemFont(ofSize: noteFontSizeForCurrentZoom())
        textView.font = font
        textView.typingAttributes[.font] = font
        if let storage = textView.textStorage, storage.length > 0 {
            storage.addAttribute(.font, value: font, range: NSRange(location: 0, length: storage.length))
        }
    }

    private func noteContainsPoint(_ point: NSPoint) -> Bool {
        for entry in noteEntries where !entry.view.isHidden {
            if entry.view.frame.contains(point) {
                return true
            }
        }
        return false
    }

    private func moveNote(at index: Int, byScaledDelta delta: NSPoint) {
        guard noteEntries.indices.contains(index) else { return }
        var entry = noteEntries[index]
        let scale = CGFloat(horizontalCalibration.currentZoom)
        if scale != 0 {
            entry.absoluteAnchor.x += delta.x / scale
            entry.absoluteAnchor.y += delta.y / scale
        }
        noteEntries[index] = entry
        updateNoteFrames()
    }

    private func moveNote(for noteView: NoteContainerView?, byScaledDelta delta: NSPoint) {
        guard let noteView = noteView else { return }
        guard let index = noteEntries.firstIndex(where: { $0.view === noteView }) else { return }
        moveNote(at: index, byScaledDelta: delta)
    }

    private func noteIndex(near point: NSPoint) -> Int? {
        guard noteEntries.count > 0 else { return nil }
        for (index, entry) in noteEntries.enumerated() {
            let frame = entry.view.frame
            let expandedFrame = frame.insetBy(dx: -noteHitSlop, dy: -noteHitSlop)
            if expandedFrame.contains(point) && !frame.contains(point) {
                return index
            }
        }
        return nil
    }

    @objc func tweakCaliper(_ sender: AnyObject) {
        delegate?.resetTouchBar()
        chosenCaliper?.isTweaking = true
        clearChosenComponents(exceptFor: chosenCaliper)
        if let componentName = Caliper.componentName(chosenCaliper?.chosenComponent ?? .noComponent) {
            let message = String(format: NSLocalizedString("tweakMessage", comment:""), componentName)
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
            imageView?.mouseDragged(with: theEvent)
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
                            if let index = calipers.firstIndex(of: c) {
                                calipers.remove(at: index)
                            }
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
            imageView?.mouseUp(with: theEvent)
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
                if let index = calipers.firstIndex(of: c) {
                    calipers.remove(at: index)
                }
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

    func updateDefaultCalibrationStrings(horizontal: String?, vertical: String?) {
        if let horizontal = horizontal {
            horizontalCalibration.calibrationString = horizontal
        }
        if let vertical = vertical {
            verticalCalibration.calibrationString = vertical
        }
    }
    
    func updateCaliperPreferences(
        unselectedColor: NSColor?,
        selectedColor: NSColor?,
        lineWidth: Int,
        rounding: Rounding,
        autoPositionText: Bool,
        timeCaliperTextPosition: TextPosition,
        amplitudeCaliperTextPosition: TextPosition,
        numberOfMarchingComponents: Int,
        deemphasizeMarchingComponents: Bool
    ) {
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
                c.numberOfMarchingComponants = numberOfMarchingComponents
                c.deemphasizeMarchingComponents = deemphasizeMarchingComponents
            }
            else if c.direction == .vertical {
                c.textPosition = amplitudeCaliperTextPosition
            }
        }
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        for c in calipers {
            c.drawWithContext(context, inRect: dirtyRect)
        }
        // This matches the background of the other views.
        if hasNoImage() && !isTransparent {
            NSColor.windowBackgroundColor.setFill()
            dirtyRect.fill()
        }
    }

    private func hasNoImage() -> Bool {
        if let imageView = imageView {
            return !imageView.hasImage()
        }
        return false
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
