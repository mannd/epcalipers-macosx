//
//  MainWindowController.swift
//  EP Calipers
//
//  Created by David Mann on 12/27/15.
//  Copyright © 2015 EP Studios. All rights reserved.
//

import Cocoa
import Quartz
import AppKit

protocol QTcResultProtocol {
    func calculate(qtInSec: Double, rrInSec: Double, formula: QTcFormulaPreference,
                   convertToMsec: Bool, units: String) -> String
}

class MainWindowController: NSWindowController, NSTextFieldDelegate, CalipersViewDelegate, NSDraggingDestination, NSMenuItemValidation, NSToolbarDelegate {

    let appName = NSLocalizedString("EP Calipers", comment:"")

    @IBOutlet weak var toolbar: NSToolbar!

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var imageView: IKImageView!
    @IBOutlet weak var calipersView: CalipersView!

    // Note textInputView must be a strong reference to prevent deallocation
    @IBOutlet var textInputView: NSView!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet var numberInputView: NSView!
    @IBOutlet weak var numberStepper: NSStepper!
    @IBOutlet weak var numberTextField: NSTextField!
    @IBOutlet var qtcNumberInputView: NSView!
    @IBOutlet weak var qtcNumberStepper: NSStepper!
    @IBOutlet weak var qtcNumberTextField: NSTextField!

    @IBOutlet var pageInputView: NSView!
    @IBOutlet weak var pageTextField: NSTextField!
    
    // InfoWindow
    @IBOutlet var instructionPanel: NSPanel!
    @IBOutlet var instructionLabel: NSTextField!

    // Preferences accessory view
    @IBOutlet var preferencesAccessoryView: NSView!
    @IBOutlet weak var caliperColorWell: NSColorWell!
    @IBOutlet weak var highlightedCaliperColorWell: NSColorWell!
    @IBOutlet weak var lineWidthSlider: NSSlider!
    @IBOutlet weak var defaultHorizontalCalibrationTextField: NSTextField!
    @IBOutlet weak var defaultVerticalCalibrationTextField: NSTextField!
    @IBOutlet weak var numberOfMeanRRIntervalsTextField: NSTextField!
    @IBOutlet weak var numberOfMeanRRIntervalsStepper: NSStepper!
    @IBOutlet weak var numberOfQTcMeanRRIntervalsTextField: NSTextField!
    @IBOutlet weak var numberOfQTcMeanRRIntervalsStepper: NSStepper!
    @IBOutlet weak var showPromptsCheckBox: NSButton!
    @IBOutlet weak var transparencyCheckBox: NSButton!
    @IBOutlet weak var showSampleECGCheckBox: NSButton!
    @IBOutlet weak var roundingPopUpButton: NSPopUpButton!
    @IBOutlet weak var formulaPopUpButton: NSPopUpButton!
    @IBOutlet weak var autoPositionTextCheckBox: NSButton!
    @IBOutlet weak var timeCaliperTextPositionPopUpButton: NSPopUpButton!
    @IBOutlet weak var amplitudeCaliperTextPositionPopUpButton: NSPopUpButton!

    @IBOutlet var marchingComponentsTextField: NSTextField!

    @IBOutlet var marchingComponentsStepper: NSStepper!

    @IBOutlet weak var calipersViewTrailingContraint: NSLayoutConstraint!
    @IBOutlet weak var calipersViewBottomConstraint: NSLayoutConstraint!

    let defaultHorizontalCalibration = NSLocalizedString("1000 msec", comment: "")
    let defaultVerticalCalibration = NSLocalizedString("10 mm", comment: "")
    
    var imageProperties: NSDictionary = Dictionary<String, String>() as NSDictionary
    var imageUTType: String = ""
    var saveOptions: IKSaveOptions = IKSaveOptions()
    var imageURL: URL? = nil
    var firstWindowResize = true
    
    var inQTcStep1 = false {
        didSet {
            resetTouchBar()
        }
    }
    var inQTcStep2 = false {
        didSet {
            resetTouchBar()
        }
    }
    var inCalibration = false
    var inMeanRR = false {
        didSet {
            if #available(OSX 10.12.2, *) {
                self.touchBar = nil
            }
        }
    }
    var rrIntervalForQTc: Double = 0.0
    
    let calipersMenuTag = 999
    let appPreferences = Preferences()
    var preferencesAlert: NSAlert? = nil
    var calibrationAlert: NSAlert? = nil
    var meanIntervalAlert: NSAlert? = nil
    var qtcMeanIntervalAlert: NSAlert? = nil
    
    // These are taken from the Apple IKImageView demo
    let zoomInFactor: CGFloat = 1.414214
    let zoomOutFactor: CGFloat = 0.7071068
    
    var fileTypeIsOk = false
    
    // PDF variables
    // PDF page numbering starts at 1
    var pdfPageNumber = 1
    var numberOfPDFPages = 0
    var imageIsPDF = false
    var pdfRef: NSPDFImageRep? = nil
    
    var oldWindowTitle : String? = nil
    var lastMessage: String? = ""

    private var isTransparent: Bool = false
    var transparent : Bool {
        get {
            return isTransparent
        }
        set (newValue) {
            isTransparent = newValue
            setTransparency()
        }
    }

    @IBAction func makeTransparent(_ sender: AnyObject) {
        isTransparent = !isTransparent
        // reset the touchbar
        if #available(OSX 10.12.2, *) {
            self.touchBar = nil
        } 
        setTransparency()
        appPreferences.transparency = isTransparent
    }

    func setTransparency() {
        calipersView.lockedMode = isTransparent
        calipersView.isTransparent = isTransparent
        clearCalibration()
        if isTransparent {
            calipersView.deleteAllCalipers()
            scrollView.drawsBackground = false
            scrollView.hasVerticalScroller = false
            scrollView.hasHorizontalScroller = false
            window?.backgroundColor = NSColor.clear
            window?.hasShadow = false
            imageView.isHidden = true
            self.window?.title = appName
        }
        else {
            scrollView.drawsBackground = true
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = true
            window?.backgroundColor = NSColor.windowBackgroundColor
            window?.hasShadow = true
            imageView.isHidden = false
            if let title = oldWindowTitle {
                self.window?.setTitleWithRepresentedFilename(title)
            }
            else {
                self.window?.title = appName
            }
        }
        // Make sure calibration button not stuck off if in middle of QTc measurement.
        exitQTc()
    }
        
    override var windowNibName: NSNib.Name? {
        return "MainWindowController"
    }
    
    override func awakeFromNib() {
        print("awakeFromNib")
        // 2 lines below added for Swift 
        let NSURLPboardType = NSPasteboard.PasteboardType(rawValue: kUTTypeURL as String)
        let NSFilenamesPboardType = NSPasteboard.PasteboardType(rawValue: kUTTypeItem as String)
        let types = [NSFilenamesPboardType, NSURLPboardType, NSPasteboard.PasteboardType.tiff]
        self.window?.registerForDraggedTypes(types)

        imageView.editable = true
        imageView.doubleClickOpensImageEditPanel = false // EditPanel broken in newest macOS versions
        imageView.zoomImageToActualSize(self)
        imageView.autoresizes = false
        imageView.currentToolMode = IKToolModeNone
        imageView.supportsDragAndDrop = false // handled by app, not by ImageKit
        imageView.delegate = self

        calipersView.nextResponder = scrollView
        calipersView.imageView = imageView
        calipersView.scrollView = scrollView
        calipersView.horizontalCalibration.direction = .horizontal
        calipersView.verticalCalibration.direction = .vertical
        clearMessage()
        if NSWindowController.instancesRespond(to: #selector(NSObject.awakeFromNib)) {
            super.awakeFromNib()
        }
    }
    
    override func windowDidLoad() {
        print("windowDidLoad")
        super.windowDidLoad()
        // register preference defaults and load preferences
        appPreferences.registerDefaults()

        Bundle.main.loadNibNamed("View", owner: self, topLevelObjects: nil)
        numberTextField.delegate = self
        numberOfMeanRRIntervalsTextField.delegate = self
        numberOfQTcMeanRRIntervalsTextField.delegate = self
        marchingComponentsTextField.delegate = self
        qtcNumberTextField.delegate = self
        
        if let path = Bundle.main.path(forResource: "sampleECG", ofType: "jpg"), appPreferences.showSampleECG {
            let url = URL(fileURLWithPath: path)
            self.openImageUrl(url, addToRecentDocuments: false, isSampleECG: true)
        }

        self.window?.isOpaque = false
        transparent = appPreferences.transparency

        calipersView.delegate = self

        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.25
        scrollView.maxMagnification = 10.0
        // Main queue needs a little time to settle before setting magnification, apparently.
        DispatchQueue.main.async {
            self.scrollView.magnification = 1.0
        }

        calipersView.horizontalCalibration.currentZoom = Double(scrollView.magnification)
        calipersView.verticalCalibration.currentZoom = Double(scrollView.magnification)
        calipersView.horizontalCalibration.originalZoom = Double(scrollView.magnification)
        calipersView.verticalCalibration.originalZoom = Double(scrollView.magnification)

        // Draw concurrently, possibly not safe, as must guarantee thread-safety of the view, so...
//        calipersView.canDrawConcurrently = true
//        self.window?.allowsConcurrentViewDrawing = true

        instructionPanel.setIsVisible(false)
        instructionPanel.becomesKeyOnlyIfNeeded = true

        toolbar.delegate = self

        scrollView.postsFrameChangedNotifications = true
        scrollView.contentView.postsBoundsChangedNotifications = true;
        NotificationCenter.default.addObserver(self, selector:#selector(imageBoundsDidChange), name: NSView.boundsDidChangeNotification, object:scrollView.contentView)
        NotificationCenter.default.addObserver(self, selector:#selector(imageFrameDidChange), name:NSView.frameDidChangeNotification, object:scrollView.contentView)
        NotificationCenter.default.addObserver(self, selector: #selector(scrollBarsDidChange), name: NSScroller.preferredScrollerStyleDidChangeNotification, object: nil)
    }

    @objc
    func imageBoundsDidChange() {
        calipersView.updateCalibration()
    }

    @objc
    func imageFrameDidChange() {
        calipersView.updateCalibration()
    }

    @objc
    func scrollBarsDidChange() {
//        NSLog("scrollbars did change")
//        NSLog("scrollbar style = %@", scrollView.scrollerStyle == .legacy ? "legacy" : "overlay")
        if scrollView.scrollerStyle == .legacy {
            calipersViewBottomConstraint.constant = 16
            calipersViewTrailingContraint.constant = 16
        } else {
            calipersViewBottomConstraint.constant = 0
            calipersViewTrailingContraint.constant = 0
        }

    }

    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation  {
        if checkExtension(sender) == true {
            self.fileTypeIsOk = true
            return .copy
        } else {
            self.fileTypeIsOk = false
            return NSDragOperation()
        }
    }
    
    func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if self.fileTypeIsOk {
            return .copy
        } else {
            return NSDragOperation()
        }
    }
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let board = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray {
            if let imagePath = board[0] as? String {
                let url = URL(fileURLWithPath: imagePath)
                openURL(url, addToRecentDocuments: true)
                return true
            }
        }
        return false
    }
    
    func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        if let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
            let path = board[0] as? String {
            let url = URL(fileURLWithPath: path)
            let suffix = url.pathExtension
            for ext in validFileExtensions() {
                if ext == suffix {
                    return true
                }
            }
            
        }
        return false
    }

    @objc func validateToolbarItem(_ toolbarItem: NSToolbarItem) -> Bool {
        if toolbarItem.itemIdentifier.rawValue == "newZoomToolbar" {
            return !isTransparent && hasImage()
        }
        if toolbarItem.itemIdentifier.rawValue == "newCalipersToolbar" {
            return hasImage() || isTransparent
        }
        if toolbarItem.itemIdentifier.rawValue == "newCalibrationToolbar" {
            return !doingMeasurement() && !calipersView.isTweakingComponent && (hasImage() || isTransparent)
        }
        if toolbarItem.itemIdentifier.rawValue == "newMeasurementToolbar" {
            return calipersView.horizontalCalibration.calibrated && calipersView.horizontalCalibration.canDisplayRate && (hasImage() || isTransparent)
        }
        return true
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(MainWindowController.doRotation(_:)) {
            return !transparent && hasImage() && !(calipersView.horizontalCalibration.calibrated || calipersView.verticalCalibration.calibrated)
        }
        if menuItem.action == #selector(MainWindowController.doMeasurement(_:)) {
            return calipersView.horizontalCalibration.calibrated && !inMeanRR && !inCalibration && calipersView.horizontalCalibration.canDisplayRate && (hasImage() || isTransparent)
        }
        if menuItem.action == #selector(MainWindowController.previousPage(_:)) {
            return !transparent && imageIsPDF && pdfPageNumber > 0 && hasImage()
        }
        if menuItem.action == #selector(MainWindowController.gotoPage(_:)) {
            return !transparent && imageIsPDF && numberOfPDFPages > 1 && hasImage()
        }
        if menuItem.action == #selector(MainWindowController.nextPage(_:)) {
            return !transparent && imageIsPDF && pdfPageNumber < numberOfPDFPages - 1 && hasImage()
        }
        if menuItem.action == #selector(MainWindowController.doZoom(_:)) {
            return !transparent && hasImage()
        }
        if menuItem.action == #selector(doCalibration(_:)) {
            return !doingMeasurement() && !calipersView.isTweakingComponent && (hasImage() || isTransparent)
        }
        if menuItem.action == #selector(deleteAllCalipers(_:)) {
            return !(calipersView.calipers.count < 1)
        }
        if menuItem.action == #selector(makeTransparent(_:)) {
            menuItem.state = isTransparent ? .on : .off
        }
        if menuItem.action == #selector(addCaliper(_:)) {
            return hasImage() || isTransparent
        }
        return true
    }

    private func hasImage() -> Bool {
        return imageView.hasImage()
    }

    private func doingMeasurement() -> Bool {
        return inMeanRR || inQTcStep1 || inQTcStep2
    }

    @IBAction func showPreferences(_ sender: AnyObject) {
        // preferencesAlert must be a persistent variable, or else values disappear from textfields with tabbing.
        // See http://stackoverflow.com/questions/14615094/nstextfield-text-disappears-sometimes
        // Note there is an autolayout bug here, probable introduced in macOS 10.12
        // see http://openradar.appspot.com/28700495
        if preferencesAlert == nil {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("EP Calipers preferences", comment:"")
            alert.accessoryView = preferencesAccessoryView
            alert.addButton(withTitle: NSLocalizedString("OK", comment:""))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment:""))
            preferencesAlert = alert
        }
        guard let preferencesAlert = preferencesAlert else { return }
        fillQTcFormulaPopUp()
        fillRoundingPopUp()
        fillTimeCaliperTextPositionPopUp()
        fillAmplitudeCaliperTextPositionPopUp()
        let timeCaliperTextPositionArray: [TextPosition] = [.centerAbove, .centerBelow, .left, .right]
        let amplitudeCaliperTextPositionArray: [TextPosition] = [.top, .bottom, .left, .right]
        let timeCaliperTextPositionIndex = timeCaliperTextPositionArray.firstIndex(of: appPreferences.timeCaliperTextPosition) ?? 0
        let amplitudeCaliperTextPositionIndex = amplitudeCaliperTextPositionArray.firstIndex(of: appPreferences.amplitudeCaliperTextPosition) ?? 0
        timeCaliperTextPositionPopUpButton.selectItem(at: timeCaliperTextPositionIndex)
        amplitudeCaliperTextPositionPopUpButton.selectItem(at: amplitudeCaliperTextPositionIndex)
        caliperColorWell.color = appPreferences.caliperColor
        highlightedCaliperColorWell.color = appPreferences.highlightColor
        lineWidthSlider.integerValue = appPreferences.lineWidth

        if let calibration = appPreferences.defaultHorizontalCalibration {
            defaultHorizontalCalibrationTextField.stringValue = calibration
        }
        if let calibration = appPreferences.defaultVerticalCalibration {
            defaultVerticalCalibrationTextField.stringValue = calibration
        }


        numberOfMeanRRIntervalsTextField.integerValue = appPreferences.defaultNumberOfMeanRRIntervals
        numberOfMeanRRIntervalsStepper.integerValue = appPreferences.defaultNumberOfMeanRRIntervals
        numberOfQTcMeanRRIntervalsTextField.integerValue = appPreferences.defaultNumberOfQTcMeanRRIntervals
        numberOfQTcMeanRRIntervalsTextField.integerValue = appPreferences.defaultNumberOfQTcMeanRRIntervals
        showPromptsCheckBox.state = NSControl.StateValue(rawValue: appPreferences.showPrompts ? 1 : 0)

        marchingComponentsTextField.integerValue = appPreferences.numberOfMarchingComponents
        marchingComponentsStepper.integerValue = appPreferences.numberOfMarchingComponents
        
        transparencyCheckBox.state = NSControl.StateValue(rawValue: appPreferences.transparency ? 1 : 0)
        showSampleECGCheckBox.state = NSControl.StateValue(rawValue: appPreferences.showSampleECG ? 1 : 0)
        autoPositionTextCheckBox.state = NSControl.StateValue(rawValue: appPreferences.autoPositionText ? 1 : 0)
        formulaPopUpButton.selectItem(at: appPreferences.qtcFormula.rawValue)
        roundingPopUpButton.selectItem(at: appPreferences.rounding.rawValue)
        let result = preferencesAlert.runModal()
        if result == NSApplication.ModalResponse.alertFirstButtonReturn {
            // assign new preferences
            appPreferences.caliperColor = caliperColorWell.color
            appPreferences.highlightColor = highlightedCaliperColorWell.color
            appPreferences.lineWidth = lineWidthSlider.integerValue
            // Note stepper is limited to number range, while text field isn't.
            appPreferences.numberOfMarchingComponents = marchingComponentsStepper.integerValue
            // Avoid empty calibration strings, so reset to defaults if empty
            if !defaultHorizontalCalibrationTextField.stringValue.isEmpty {
                appPreferences.defaultHorizontalCalibration = defaultHorizontalCalibrationTextField.stringValue
            }
            if !defaultVerticalCalibrationTextField.stringValue.isEmpty {
                appPreferences.defaultVerticalCalibration = defaultVerticalCalibrationTextField.stringValue
            }
            appPreferences.defaultNumberOfMeanRRIntervals = numberOfMeanRRIntervalsStepper.integerValue
            appPreferences.defaultNumberOfQTcMeanRRIntervals = numberOfQTcMeanRRIntervalsStepper.integerValue
            appPreferences.showPrompts = showPromptsCheckBox.integerValue == 1 ? true : false
            appPreferences.transparency = transparencyCheckBox.integerValue == 1 ? true : false
            appPreferences.showSampleECG = showSampleECGCheckBox.integerValue == 1 ? true : false
            appPreferences.autoPositionText = autoPositionTextCheckBox.integerValue == 1 ? true : false
            appPreferences.timeCaliperTextPosition = timeCaliperTextPositionArray[timeCaliperTextPositionPopUpButton.indexOfSelectedItem]
            appPreferences.amplitudeCaliperTextPosition = amplitudeCaliperTextPositionArray[amplitudeCaliperTextPositionPopUpButton.indexOfSelectedItem]
            appPreferences.qtcFormula = QTcFormulaPreference(rawValue: formulaPopUpButton.indexOfSelectedItem) ?? QTcFormulaPreference.Bazett
            appPreferences.rounding = Rounding(rawValue: roundingPopUpButton.indexOfSelectedItem) ?? Rounding.ToInteger
            appPreferences.savePreferences()
            // update calipersView
            calipersView.updateCaliperPreferences(
                unselectedColor: appPreferences.caliperColor,
                selectedColor: appPreferences.highlightColor,
                lineWidth: appPreferences.lineWidth,
                rounding: appPreferences.rounding,
                autoPositionText: appPreferences.autoPositionText,
                timeCaliperTextPosition: appPreferences.timeCaliperTextPosition,
                amplitudeCaliperTextPosition: appPreferences.amplitudeCaliperTextPosition,
                numberOfMarchingComponents: appPreferences.numberOfMarchingComponents
            )
            // update transparency
            if transparent != appPreferences.transparency {
                transparent = appPreferences.transparency
            }

            calipersView.horizontalCalibration.calibrationString = appPreferences.defaultHorizontalCalibration ?? defaultHorizontalCalibration
            calipersView.verticalCalibration.calibrationString = appPreferences.defaultVerticalCalibration ?? defaultVerticalCalibration
        }
    }
    
    private func fillQTcFormulaPopUp() {
        formulaPopUpButton.removeAllItems()
        formulaPopUpButton.addItem(withTitle: "Bazett")
        formulaPopUpButton.addItem(withTitle: "Framingham")
        formulaPopUpButton.addItem(withTitle: "Hodges")
        formulaPopUpButton.addItem(withTitle: "Fridericia")
        formulaPopUpButton.addItem(withTitle: NSLocalizedString("All", comment: ""))
    }

    private func fillRoundingPopUp() {
        roundingPopUpButton.removeAllItems()
        roundingPopUpButton.addItem(withTitle: NSLocalizedString("To integer", comment: ""))
        roundingPopUpButton.addItem(withTitle: NSLocalizedString("To 4 digits", comment: ""))
        roundingPopUpButton.addItem(withTitle: NSLocalizedString("To tenths", comment: ""))
        roundingPopUpButton.addItem(withTitle: NSLocalizedString("To hundredths", comment: ""))
        // TODO: remove in production.  For debugging only.
        //roundingPopUpButton.addItem(withTitle: "Raw")
    }

    private func fillTimeCaliperTextPositionPopUp() {
        timeCaliperTextPositionPopUpButton.removeAllItems()
        timeCaliperTextPositionPopUpButton.addItem(withTitle: NSLocalizedString("Center above", comment: ""))
        timeCaliperTextPositionPopUpButton.addItem(withTitle: NSLocalizedString("Center below", comment: ""))
        timeCaliperTextPositionPopUpButton.addItem(withTitle: NSLocalizedString("Left", comment: ""))
        timeCaliperTextPositionPopUpButton.addItem(withTitle: NSLocalizedString("Right", comment: ""))
    }

    private func fillAmplitudeCaliperTextPositionPopUp() {
        amplitudeCaliperTextPositionPopUpButton.removeAllItems()
        amplitudeCaliperTextPositionPopUpButton.addItem(withTitle: NSLocalizedString("Top", comment: ""))
        amplitudeCaliperTextPositionPopUpButton.addItem(withTitle: NSLocalizedString("Bottom", comment: ""))
        amplitudeCaliperTextPositionPopUpButton.addItem(withTitle: NSLocalizedString("Left", comment: ""))
        amplitudeCaliperTextPositionPopUpButton.addItem(withTitle: NSLocalizedString("Right", comment: ""))
    }

    @IBAction func numberOfMeanRRStepperAction(_ sender: AnyObject) {
        numberOfMeanRRIntervalsTextField.integerValue = numberOfMeanRRIntervalsStepper.integerValue
    }
    
    @IBAction func numberOfQTcMeanRRStepperAction(_ sender: AnyObject) {
        numberOfQTcMeanRRIntervalsTextField.integerValue = numberOfQTcMeanRRIntervalsStepper.integerValue
    }


    
    @IBAction func gotoPage(_ sender: Any) {
        getPageNumber()
    }
    
    @IBAction func doZoom(_ sender: AnyObject) {
        var zoom: Int
        var zoomFactor: CGFloat
        if sender is NSSegmentedControl {
            zoom = sender.selectedSegment
        }
        else {
            zoom = sender.tag
        }
        switch zoom {
        case 0:
            zoomFactor = scrollView.magnification
            scrollView.magnification = zoomFactor * zoomInFactor

//            zoomFactor = imageView.zoomFactor
//            imageView.zoomFactor = zoomFactor * zoomInFactor
            calipersView.updateCalibration()
        case 1:
            zoomFactor = scrollView.magnification
            scrollView.magnification = scrollView.magnification * zoomOutFactor
//            zoomFactor = imageView.zoomFactor
//            imageView.zoomFactor = zoomFactor * zoomOutFactor
            calipersView.updateCalibration()
        case 2:
            scrollView.magnification = 1.0
//            imageView.zoomImageToActualSize(self)
            calipersView.updateCalibration()
        default:
            break
        }
    }
    
    @IBAction func doMeasurement(_ sender: AnyObject) {
        var measurement: Int
        if sender is NSSegmentedControl {
            measurement = sender.selectedSegment
        }
        else {
            measurement = sender.tag
        }
        switch measurement {
        case 0:
            toggleIntervalRate()
        case 1:
            meanRRWithPossiblePrompts()
        case 2:
            calculateQTc()
        case 3:
            cancelMeasurement()
        default:
            break
        }
    }

    func cancelMeasurement() {
        resetAllMeasurements()
    }

    func setInstructionText(_ text: String) {
        instructionLabel.stringValue = text
    }

    @IBAction func openImage(_ sender: AnyObject) {
        /* Present open panel. */
        guard let window = self.window else { return }
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = validFileExtensions()
        openPanel.canSelectHiddenExtension = true
        openPanel.beginSheetModal(for: window,
            completionHandler: {
                (result: NSApplication.ModalResponse) -> Void in
                if result == .OK {
                    self.openURL(openPanel.url, addToRecentDocuments: true)
               }
            }
        )
    }
    
    func validFileExtensions() -> [String] {
        let extensions = "jpg/jpeg/JPG/JPEG/png/PNG/tiff/tif/TIFF/TIF/bmp/BMP/pdf/PDF"
        return extensions.components(separatedBy: "/")
    }
    
    func openURL(_ url: URL?, addToRecentDocuments: Bool) {
        // ensure no opening of anything if transparent mode
        if transparent {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Transparent window mode on", comment:"")
            alert.informativeText = NSLocalizedString("Do you want to turn off transparent window mode and load image?", comment:"")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("Turn off transparency and load image", comment:""))
            alert.addButton(withTitle: NSLocalizedString("Keep transparency and don't load image", comment:""))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment:""))
            let result = alert.runModal()
            if result == NSApplication.ModalResponse.alertFirstButtonReturn {
                transparent = false
                appPreferences.transparency = transparent
                appPreferences.savePreferences()
            }
            else {
                return
            }
        }
        if let goodURL = url {
            clearPDF()
            if isPDFFile((goodURL as NSURL).filePathURL) {
                openPDF(goodURL, addToRecentDocuments: addToRecentDocuments)
            }
            else {
                self.openImageUrl(goodURL, addToRecentDocuments: addToRecentDocuments)
            }
        }
    }
    
    func clearPDF() {
        imageIsPDF = false
        pdfPageNumber = 0
        numberOfPDFPages = 0
    }
    
    func isPDFFile(_ filePath: URL?) -> Bool {
        if let path = filePath {
            let ext = path.pathExtension
            return ext.uppercased() == "PDF"
        }
        return false
    }
    
    enum OpenError : Error {
        case Nonspecific
    }
    
    func openImageUrl(_ url: URL, addToRecentDocuments: Bool, isSampleECG: Bool = false) {
        // See http://cocoaintheshell.whine.fr/2012/08/kcgimagesourceshouldcache-true-default-value/
        do {
            let reachable = try (url as URL).checkResourceIsReachable()
            // Setting imageview with url, as in imageView.setImage(url:) can crash program,
            // if you are loading a large image and then try to scroll it.  Must load as below.
            if reachable, let data = NSData(contentsOf: url), let image = NSImage(data: data as Data) {
                self.imageView.setImage(image.cgImage(forProposedRect: nil, context: nil, hints: nil), imageProperties: nil)
                self.imageView.zoomImageToActualSize(self)
                let urlPath = url.path
                if !isSampleECG {
                    // We just use app name when showing sample ECG
                    self.oldWindowTitle = urlPath
                    self.window?.setTitleWithRepresentedFilename(urlPath)
                }
                self.imageURL = url
                self.clearCalibration()
                if addToRecentDocuments {
                    NSDocumentController.shared.noteNewRecentDocumentURL(url)
                }
            }
            else {
                throw OpenError.Nonspecific
            }
        }
        catch _ {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("File not opened", comment:"")
            alert.informativeText = NSLocalizedString("Can't open \(url)", comment:"")
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    // secret IKImageView delegate method
    // see http://www.theregister.co.uk/2008/10/14/mac_secrets_imagekit_internals/
    func imagePathChanged(_ path: String) {
        let url = URL(fileURLWithPath: path)
        openURL(url, addToRecentDocuments: true)
    }
    
    // This action has been removed
    @IBAction func saveImage(_ sender: AnyObject) {
        // Save image for now is just uses the system screenshot utility
        if !calipersView.takeScreenshot() {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("Screenshot cancelled", comment:"")
            alert.informativeText = NSLocalizedString("Screenshot cancelled by user.  This message may also appear if there is a problem taking a screenshot on your machine.", comment:"")
            alert.runModal()
        }
    }

    // see http://stackoverflow.com/questions/15246563/extract-nsimage-from-pdfpage-with-varying-resolution?rq=1 and http://stackoverflow.com/questions/1897019/convert-pdf-pages-to-images-with-cocoa
    func openPDF(_ url: URL, addToRecentDocuments: Bool) {
        do {
            if let pdfData = try? Data(contentsOf: url), let pdf = NSPDFImageRep(data: pdfData) {
                pdfRef = pdf
                numberOfPDFPages = pdf.pageCount
                imageIsPDF = true
                showPDFPage(pdf, page: 0)
                let urlPath = url.path
                self.window?.setTitleWithRepresentedFilename(urlPath)
                imageURL = url
                clearCalibration()
                if addToRecentDocuments {
                    NSDocumentController.shared.noteNewRecentDocumentURL(url)
                }
            }
            else {
                throw OpenError.Nonspecific
            }
        }
        catch _ {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("File not opened", comment:"")
            alert.informativeText = NSLocalizedString("Can't open \(url)", comment:"")
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    func showPDFPage(_ pdf: NSPDFImageRep, page: Int) {
        // consider add preference for low res, hi res (2.0, 4.0 scale?)
        let scale: CGFloat = 4.0
        pdf.currentPage = page
        var tempImage = NSImage()
        tempImage.addRepresentation(pdf)
        tempImage = scaleImage(tempImage, byFactor: scale)
        guard let image = nsImageToCGImage(tempImage) else { return }
        imageView.setImage(image, imageProperties: nil)
        imageView.zoomImageToActualSize(self)
        // keep size of image manageable by scaling down
        imageView.zoomFactor = imageView.zoomFactor / scale
        calipersView.updateCalibration()
    }
    
    // see http://stackoverflow.com/questions/12223739/ios-to-mac-graphiccontext-explanation-conversion
    func scaleImage(_ image: NSImage, byFactor factor: CGFloat) -> NSImage {
        let newSize = NSMakeSize(image.size.width * factor, image.size.height * factor)
        let scaledImage = NSImage(size: newSize)
        scaledImage.lockFocus()
        NSColor.white.set()
        NSBezierPath.fill(NSMakeRect(0, 0, newSize.width, newSize.height))
        let transform = NSAffineTransform()
        transform.scale(by: factor)
        transform.concat()
        image.draw(at: NSZeroPoint, from: NSZeroRect, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
        scaledImage.unlockFocus()
        return scaledImage
    }
    
    // convert NSImage to CGImage
    // from http://lists.apple.com/archives/cocoa-dev/2010/May/msg01171.html
    func nsImageToCGImage(_ image: NSImage) -> CGImage? {
        let imageData = image.tiffRepresentation
        var imageRef: CGImage? = nil
        if let imgData = imageData {
            if let imageSource = CGImageSourceCreateWithData(imgData as CFData, nil) {
                imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
            }
        }
        return imageRef
    }
    
    @IBAction func previousPage(_ sender: AnyObject) {
        pdfPageNumber -= 1
        pdfPageNumber = pdfPageNumber < 0 ? 0 : pdfPageNumber
        if let pdf = pdfRef {
            showPDFPage(pdf, page: pdfPageNumber)
        }
    }
    
    @IBAction func nextPage(_ sender: AnyObject) {
        pdfPageNumber += 1
        pdfPageNumber = pdfPageNumber >= numberOfPDFPages ? numberOfPDFPages - 1 : pdfPageNumber
        if let pdf = pdfRef {
            showPDFPage(pdf, page: pdfPageNumber)
        }
    }
    
    @IBAction func doRotation(_ sender: AnyObject) {
        var rotationType: Int
        if sender is NSSegmentedControl {
            rotationType = sender.selectedSegment
        }
        else {
            rotationType = sender.tag
        }
        switch rotationType {
        case 0:
            rotateImageView(-90)
        case 1:
            rotateImageView(90)
        case 2:
            rotateImageView(-1)
        case 3:
            rotateImageView(1)
        case 4:
            rotateImageView(-0.1)
        case 5:
            rotateImageView(0.1)
        case 6:
            resetImageViewRotation()
        default:
            break
        }
    }
    
    func radians(_ degrees: Double) -> Double {
        return degrees * 3.14159265359 / 180.0
    }
    
    func rotateImageView(_ degrees: Double) {
        imageView.rotationAngle += CGFloat(radians(degrees))
        adjustImageAfterRotation()
        
    }
    
    func resetImageViewRotation() {
        imageView.rotationAngle = 0
        adjustImageAfterRotation()
    }
    
    func adjustImageAfterRotation() {
        imageView.zoomImageToActualSize(self)
        // since rotation can adjust zoom factor, must clear calibration
        clearCalibration()
    }

// MARK: Caliper functions
    
    func addCaliperWithDirection(_ direction: CaliperDirection) {
        let caliper = Caliper()
        // initiallize with Preferences here
        caliper.lineWidth = CGFloat(appPreferences.lineWidth)
        caliper.rounding = appPreferences.rounding
        caliper.unselectedColor = appPreferences.caliperColor
        caliper.selectedColor = appPreferences.highlightColor
        caliper.color = caliper.unselectedColor
        caliper.autoPositionText = appPreferences.autoPositionText
        caliper.direction = direction
        if direction == .horizontal {
            caliper.calibration = calipersView.horizontalCalibration
            caliper.textPosition = appPreferences.timeCaliperTextPosition
            caliper.numberOfMarchingComponants = appPreferences.numberOfMarchingComponents
        }
        else {
            caliper.calibration = calipersView.verticalCalibration
            caliper.textPosition = appPreferences.amplitudeCaliperTextPosition
        }
        caliper.setInitialPositionInRect(calipersView.bounds)
        calipersView.calipers.append(caliper)
        calipersView.needsDisplay = true
    }
    
    func addHorizontalCaliper() {
        addCaliperWithDirection(.horizontal)
    }
    
    func addVerticalCaliper() {
        addCaliperWithDirection(.vertical)
    }
    
    func addAngleCaliper() {
        let caliper = AngleCaliper()
        caliper.lineWidth = CGFloat(appPreferences.lineWidth)
        caliper.rounding = appPreferences.rounding
        caliper.direction = .horizontal
        caliper.autoPositionText = appPreferences.autoPositionText
        caliper.textPosition = appPreferences.timeCaliperTextPosition
        caliper.calibration = calipersView.horizontalCalibration
        caliper.verticalCalibration = calipersView.verticalCalibration
        caliper.unselectedColor = appPreferences.caliperColor
        caliper.selectedColor = appPreferences.highlightColor
        caliper.color = caliper.unselectedColor
        caliper.setInitialPositionInRect(calipersView.bounds)
        calipersView.calipers.append(caliper)
        calipersView.needsDisplay = true
    }
    
    @IBAction func addCaliper(_ sender: AnyObject) {
        var caliperType: Int
        if sender is NSSegmentedControl {
            caliperType = sender.selectedSegment
        }
        else {
            caliperType = sender.tag
        }
        switch caliperType {
        case 0:
            addHorizontalCaliper()
        case 1:
            addVerticalCaliper()
        case 2:
            addAngleCaliper()
        case 3:
            calibrateWithPossiblePrompts()
        case 4:
            clearCalibration()
        default:
            break
        }
    }

    @IBAction func doCalibration(_ sender: AnyObject) {
        print("doCalibration")
        let calibrationTag: Int
        if sender is NSSegmentedControl {
            calibrationTag = sender.selectedSegment
        }
        else {
            calibrationTag = sender.tag
        }
        print("calibrationTag = \(calibrationTag)")
        switch calibrationTag {
        case 0:
            calibrateWithPossiblePrompts()
        case 1:
            clearCalibration()
        default:
            break
        }

    }
    
    @IBAction func deleteAllCalipers(_ sender: AnyObject) {
        calipersView.deleteAllCalipers()
    }
    
    func calibrateWithPossiblePrompts() {
        if appPreferences.showPrompts {
            if inCalibration {
                // user pressed Calibrate again instead of Next, it's OK, do what s/he wants
                calibrate()
                return
            }
            showMessage(NSLocalizedString("calibrationMessage", comment:""))
            inCalibration = true
        }
        else {
            calibrate()
        }
    }
    
    func calibrate() {
        if calipersView.calipers.count < 1 {
            showNoCalipersAlert(false)
            return
        }
        if calipersView.noCaliperIsSelected() {
            if calipersView.calipers.count == 1 {
                // assume user wants to calibrate sole caliper, so select it
                calipersView.selectCaliper(calipersView.calipers[0])
            }
            else {
                showNoCaliperSelectedAlert()
                return
            }
        }
        if let c = calipersView.activeCaliper() {
            if !c.requiresCalibration {
                showAngleCaliperNoCalibrationAlert()
                return
            }
            var example: String
            if c.direction == .vertical {
                example = NSLocalizedString("1 mV", comment:"")
            }
            else {
                example = NSLocalizedString("1000 msec", comment:"")
            }
            let message = String(format:NSLocalizedString("Enter calibration measurement (e.g. %@)", comment:""), example)
            if calibrationAlert == nil {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Calibrate caliper", comment:"")
                //alert.informativeText = message
                alert.alertStyle = NSAlert.Style.informational
                alert.addButton(withTitle: NSLocalizedString("Calibrate", comment:""))
                alert.addButton(withTitle: NSLocalizedString("Cancel", comment:""))
                alert.accessoryView = textInputView
                calibrationAlert = alert
            }
            guard let calibrationAlert = calibrationAlert else { return }
            calibrationAlert.informativeText = message
            let direction = c.direction
            var calibrationString: String
            if direction == .horizontal {
                calibrationString = calipersView.horizontalCalibration.calibrationString
            }
            else {
                calibrationString = calipersView.verticalCalibration.calibrationString
            }
            textField.stringValue = calibrationString
            let result = calibrationAlert.runModal()
            if result == NSApplication.ModalResponse.alertFirstButtonReturn {
                let inputText = textField.stringValue
                if !inputText.isEmpty {
                    calibrateWithText(inputText)
                    exitCalibration()
                }
            }
        }
    }
    
    func calibrateWithText(_ inputText: String) {
        // caller must guarantee this
        assert(!inputText.isEmpty)
        var trimmedUnits: String = ""
        let scanner: Scanner = Scanner.localizedScanner(with: inputText) as! Scanner
        if var value = scanner.scanDouble() {
            trimmedUnits = scanner.string[scanner.currentIndex...].trimmingCharacters(in: CharacterSet.whitespaces)
            value = fabs(value)
            if value > 0 {
                guard let c = calipersView.activeCaliper(), c.points() > 0 else { return }

                var calibration: Calibration
                if c.direction == .horizontal {
                    calibration = calipersView.horizontalCalibration
                }
                else {
                    calibration = calipersView.verticalCalibration
                }
                calibration.calibrationString = inputText
                calibration.rawUnits = trimmedUnits
                if !calibration.canDisplayRate {
                    calibration.displayRate = false
                }
                calibration.originalZoom = Double(scrollView.magnification)
                calibration.originalCalFactor = value / Double(c.points())
                calibration.currentZoom = calibration.originalZoom
                calibration.calibrated = true
            }
            calipersView.needsDisplay = true
            
        }
    }
    
    func exitCalibration() {
        clearMessage()
        inCalibration = false
        inQTcStep1 = false
        inQTcStep2 = false
    }
    
    func showMessage(_ message: String) {
        calipersView.stopTweaking()
        showMessageWithoutSaving(message)
    }

    func resetTouchBar() {
        if #available(OSX 10.12.2, *) {
            touchBar = nil
        }
    }
    
    // This doesn't overwrite lastMessage, thus allowing multiple tweak messages that
    // will return to last pre-Tweak message when restoreLastMessage called.
    func showMessageWithoutSaving(_ message: String) {
        guard !message.isEmpty else {
            instructionPanel.setIsVisible(false)
            return
        }
        instructionPanel.setIsVisible(true)
        instructionLabel.stringValue = message
    }
    
    func showMessageAndSaveLast(_ message: String) {
        lastMessage = instructionLabel.stringValue
        instructionPanel.setIsVisible(true)
        instructionLabel.stringValue = message
    }
    
    func clearMessage() {
        instructionPanel.setIsVisible(false)
        instructionLabel.stringValue = ""
        lastMessage = nil
    }
    
    func restoreLastMessage() {
        if let message = lastMessage, !message.isEmpty {
            showMessageWithoutSaving(message)
        }
        else {
            clearMessage()
        }
    }

    func showAngleCaliperNoCalibrationAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Angle caliper", comment:"")
        alert.informativeText = NSLocalizedString("angleCalibrationMessage", comment: "")
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: NSLocalizedString("OK", comment:""))
        alert.runModal()
    }
    
    func showNoCalipersAlert(_ noTimeCaliper: Bool) {
        let alert = NSAlert()
        if noTimeCaliper {
            alert.messageText = NSLocalizedString("No time caliper available", comment:"")
            alert.informativeText = NSLocalizedString("In order to proceed, you must first add a time caliper.", comment:"")
        }
        else {
            alert.messageText = NSLocalizedString("No calipers available", comment:"")
            alert.informativeText = NSLocalizedString("In order to proceed, you must first add a caliper.", comment:"")
        }
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: NSLocalizedString("OK", comment:""))
        alert.runModal()
    }
    
    func showNoCaliperSelectedAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("No caliper selected", comment:"")
        alert.informativeText = NSLocalizedString("Select (by single-clicking it) the caliper that you want to calibrate, and then set it to a known interval, e.g. 1000 msec or 1 mV", comment:"")
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: NSLocalizedString("OK", comment:""))
        alert.runModal()
    }

    func showNoTimeCaliperSelectedAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("No time caliper selected", comment:"")
        alert.informativeText = NSLocalizedString("Select a time caliper.  Stretch the caliper over several intervals to get an average interval and rate.", comment:"")
        alert.alertStyle = NSAlert.Style.informational
        alert.addButton(withTitle: NSLocalizedString("OK", comment:""))
        alert.runModal()
    }
    
    func showDivisorErrorAlert() {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.warning
        alert.messageText = NSLocalizedString("Bad number of intervals", comment:"")
        alert.informativeText = NSLocalizedString("Please enter a number between 1 and 10", comment:"")
        alert.addButton(withTitle: NSLocalizedString("OK", comment:""))
        alert.runModal()
    }
    
    func showMeanRRResultAlert(_ meanInterval: Double, meanRate: Double, intervalUnits: String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.informational
        alert.messageText = NSLocalizedString("Mean interval and rate", comment:"")
        alert.informativeText = NSString.localizedStringWithFormat(NSLocalizedString("Mean interval = %.4g %@\nMean rate = %.4g bpm", comment:"") as NSString, meanInterval, intervalUnits, meanRate) as String;
        alert.addButton(withTitle: NSLocalizedString("OK", comment:""))
        alert.runModal()
    }

    
    func clearCalibration() {
        resetCalibration()
        calipersView.needsDisplay = true
    }
    
    func resetCalibration() {
        // calibration buttons locked during QTc and MeanRR
        // if nothing else, clear messages
        exitCalibration()
        if calipersView.horizontalCalibration.calibrated ||
            calipersView.verticalCalibration.calibrated {
            // No easy animation equivalent in Cocoa
            // flashCalipers()
            calipersView.horizontalCalibration.reset()
            calipersView.verticalCalibration.reset()
        }
    }
    
    func toggleIntervalRate() {
        // Don't do anthing if no time caliper on screen.
        guard !noTimeCaliperExists() else { return }
        calipersView.horizontalCalibration.displayRate = !calipersView.horizontalCalibration.displayRate
        calipersView.needsDisplay = true
    }
    
    func meanRRWithPossiblePrompts() {
        guard !(inQTcStep1 || inQTcStep2) else { return }
        if appPreferences.showPrompts {
            if inMeanRR {
                meanRR()
                return
            }
            showMessage(NSLocalizedString("meanRRMessage", comment:""))
            inMeanRR = true
        }
        else {
            meanRR()
        }
        
    }

    func enterMeasurements() {
        print("enterMeasurements")
        toolbar.allowsUserCustomization = false
    }

    func exitMeasurements() {
        print("exitMeasurements")
        toolbar.allowsUserCustomization = true
    }
    
    func meanRR() {
        if noTimeCaliperExists() {
            showNoCalipersAlert(true)
            exitMeanRR()
            return
        }
        let singleHorizontalCaliper = getLoneTimeCaliper()
        if let caliper = singleHorizontalCaliper {
            calipersView.selectCaliper(caliper)
            calipersView.unselectCalipersExcept(caliper)
        }
        if calipersView.noTimeCaliperIsSelected() {
            showNoTimeCaliperSelectedAlert()
            exitMeanRR()
            return
        }
        if let c = calipersView.activeCaliper() {
            if meanIntervalAlert == nil {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Enter number of intervals", comment:"")
                alert.informativeText = NSLocalizedString("How many intervals is this caliper measuring?", comment:"")
                alert.alertStyle = NSAlert.Style.informational
                alert.addButton(withTitle: NSLocalizedString("Calculate", comment:""))
                alert.addButton(withTitle: NSLocalizedString("Cancel", comment:""))
                alert.accessoryView = numberInputView
                meanIntervalAlert = alert
            }
            guard let meanIntervalAlert = meanIntervalAlert else { return }
            numberTextField.stringValue = String(appPreferences.defaultNumberOfMeanRRIntervals)
            numberStepper.integerValue = appPreferences.defaultNumberOfMeanRRIntervals
            let result = meanIntervalAlert.runModal()
            if result == NSApplication.ModalResponse.alertFirstButtonReturn {
                if numberTextField.integerValue < 1 || numberTextField.integerValue > 10 {
                    showDivisorErrorAlert()
                    exitMeanRR()
                    return
                }
                // get integer from the stepper
                let divisor = numberStepper.integerValue
                assert (divisor != 0)
                let intervalResult = fabs(c.intervalResult())
                let meanInterval = intervalResult / Double(divisor)
                let meanRate = c.rateResult(meanInterval)
                let intervalUnits = c.calibration.rawUnits
                showMeanRRResultAlert(meanInterval, meanRate: meanRate, intervalUnits: intervalUnits)
            }
        }
        exitMeanRR()
    }
    
    func exitMeanRR() {
        clearMessage()
        inMeanRR = false
    }

    func resetAllMeasurements() {
        clearMessage()
        inMeanRR = false
        inQTcStep1 = false
        inQTcStep2 = false
        inCalibration = false
        calipersView.stopTweaking()
    }
    
    func calculateQTc() {
        guard !inMeanRR else { return }
        if inQTcStep1 {
            if calipersView.noTimeCaliperIsSelected() {
                showNoTimeCaliperSelectedAlert()
                return
            }
            doQTcStep1()
            return
        }
        if inQTcStep2 {
            if calipersView.noTimeCaliperIsSelected() {
                showNoTimeCaliperSelectedAlert()
                return
            }
            doQTcResult()
            return
        }
        if noTimeCaliperExists() {
            showNoCalipersAlert(true)
            return
        }
        calipersView.horizontalCalibration.displayRate = false
        let singleHorizontalCaliper = getLoneTimeCaliper()
        if let caliper = singleHorizontalCaliper {
            calipersView.selectCaliper(caliper)
            calipersView.unselectCalipersExcept(caliper)
        }
        if calipersView.noTimeCaliperIsSelected() {
            showNoTimeCaliperSelectedAlert()
            return
        }
        enterQTc()
        showMessage(NSLocalizedString("qtcStep1Message", comment:""))
        inQTcStep1 = true
    }

    func getPageNumber() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString("Go to page", comment:"")
        alert.addButton(withTitle: NSLocalizedString("OK", comment:""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.accessoryView = pageInputView
        pageTextField.stringValue = String(pdfPageNumber + 1)
        let result = alert.runModal()
        if result == NSApplication.ModalResponse.alertFirstButtonReturn {
            var pageNumber = pageTextField.integerValue - 1
            if pageNumber < 0 {
                pageNumber = 0
            }
            if pageNumber > numberOfPDFPages - 1{
                pageNumber = numberOfPDFPages - 1
            }
            pdfPageNumber = pageNumber
            if let pdf = pdfRef {
                showPDFPage(pdf, page: pdfPageNumber)
            }
        }
    }
    
    func doQTcStep1() {
        if let c = calipersView.activeCaliper() {
            if qtcMeanIntervalAlert == nil {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = NSLocalizedString("QTc: Enter number of RR intervals", comment:"")
                alert.informativeText = NSLocalizedString("How many RR intervals is this caliper measuring?", comment:"")
                alert.addButton(withTitle: NSLocalizedString("Continue", comment:""))
                alert.addButton(withTitle: NSLocalizedString("Cancel", comment:""))
                alert.accessoryView = qtcNumberInputView
                qtcMeanIntervalAlert = alert
            }
            guard let qtcMeanIntervalAlert = qtcMeanIntervalAlert else { return }
            qtcNumberTextField.stringValue = String(appPreferences.defaultNumberOfQTcMeanRRIntervals)
            qtcNumberStepper.integerValue = appPreferences.defaultNumberOfQTcMeanRRIntervals
            let result = qtcMeanIntervalAlert.runModal()
            if result == NSApplication.ModalResponse.alertFirstButtonReturn {
                if qtcNumberTextField.integerValue < 1 || qtcNumberTextField.integerValue > 10 {
                    showDivisorErrorAlert()
                    exitQTc()
                    return
                }
                // get integer from the stepper
                let divisor = qtcNumberStepper.integerValue
                assert (divisor != 0)
                let intervalResult = fabs(c.intervalResult())
                let meanInterval = intervalResult / Double(divisor)
                rrIntervalForQTc = c.intervalInSecs(meanInterval)
                // now measure QT...
                inQTcStep1 = false
                inQTcStep2 = true
                doQTcStep2()
            }
            else {
                exitQTc()
            }
        }
        else {  // on error (c = nil) exit QTc
            exitQTc()
        }
    }
    
    func doQTcStep2() {
        showMessage(NSLocalizedString("qtcStep2Message", comment:""))
    }
    
    func doQTcResult() {
        if let c = calipersView.activeCaliper() {
            let qt = fabs(c.intervalInSecs(c.intervalResult()))
            let meanRR = fabs(rrIntervalForQTc)
            
            let qtcResult: QTcResultProtocol = QTcResult()
            let result = qtcResult.calculate(qtInSec: qt, rrInSec: meanRR, formula: appPreferences.qtcFormula,
                                   convertToMsec: c.calibration.unitsAreMsec, units: c.calibration.units)
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("Calculated QTc", comment:"")
            alert.informativeText = result
            alert.addButton(withTitle: NSLocalizedString("Done", comment:""))
            alert.addButton(withTitle: NSLocalizedString("Repeat QT", comment: ""))
            let alertResult = alert.runModal()
            if  alertResult == NSApplication.ModalResponse.alertSecondButtonReturn {
                doQTcStep2()
                return
            }
        }
        exitQTc()
    }

    func enterQTc() {
    }


    func exitQTc() {
        clearMessage()
        inQTcStep1 = false
        inQTcStep2 = false
    }

    func doNextQTcStep() {
        if inQTcStep1 {
            if calipersView.noTimeCaliperIsSelected() {
                showNoTimeCaliperSelectedAlert()
                return
            }
            doQTcStep1()
        }
        else if inQTcStep2 {
            if calipersView.noTimeCaliperIsSelected() {
                showNoTimeCaliperSelectedAlert()
                return
            }
            doQTcResult()
        }
    }

    func doPreviousQTcStep() {
        if inQTcStep1 {
            exitQTc()
        }
        if inQTcStep2 {
            // back to beginning of QTc process
            inQTcStep2 = false
            inQTcStep1 = false
            calculateQTc()
        }
        
    }

    func cancelQTcSteps() {
        exitQTc()
    }

    func getLoneTimeCaliper() -> Caliper? {
        var c: Caliper? = nil
        var n: Int = 0
        if calipersView.calipers.count > 0 {
            for caliper in calipersView.calipers {
                if caliper.direction == .horizontal && !caliper.isAngleCaliper {
                    c = caliper
                    n += 1
                }
            }
        }
        if n != 1 {
             c = nil
        }
        return c
    }
    
    func noTimeCaliperExists() -> Bool {
        var noTimeCaliperFound = true
        for c in calipersView.calipers {
            if c.direction == .horizontal && !c.isAngleCaliper {
                noTimeCaliperFound = false
            }
        }
        return noTimeCaliperFound
    }
    
    @IBAction func stepperAction(_ sender: AnyObject) {
        numberTextField.integerValue = numberStepper.integerValue
        qtcNumberTextField.integerValue = qtcNumberStepper.integerValue
    }


    @IBAction func marchingComponentsStepperAction(_ sender: Any) {
        marchingComponentsTextField.integerValue = marchingComponentsStepper.integerValue
    }

    func controlTextDidChange(_ obj: Notification) {
        if obj.name.rawValue == "NSControlTextDidChangeNotification" {
            if obj.object as AnyObject? === numberTextField {
                numberStepper.integerValue = numberTextField.integerValue
            }
            if obj.object as AnyObject? === numberOfMeanRRIntervalsTextField {
                numberOfMeanRRIntervalsStepper.integerValue = numberOfMeanRRIntervalsTextField.integerValue
            }
            if obj.object as AnyObject? === numberOfQTcMeanRRIntervalsTextField {
                numberOfQTcMeanRRIntervalsStepper.integerValue = numberOfQTcMeanRRIntervalsTextField.integerValue
            }
            if obj.object as AnyObject? === qtcNumberTextField {
                qtcNumberStepper.integerValue = qtcNumberTextField.integerValue
            }
            if obj.object as AnyObject? === marchingComponentsTextField {
                marchingComponentsStepper.integerValue = marchingComponentsTextField.integerValue
            }
        }
    }
}

@available(OSX 10.12.2, *)
extension MainWindowController: NSTouchBarDelegate {
    @objc func tweakCaliper(_ sender: AnyObject) {
        if sender is NSSegmentedControl {
            let direction = sender.selectedSegment
            switch direction {
            case 0:
                calipersView.moveLeft(sender)
            case 1:
                calipersView.moveRight(sender)
            case 2:
                calipersView.moveUp(sender)
            case 3:
                calipersView.moveDown(sender)
            default:
                break
            }
        }
    }

    @objc func cancelTweak(_ sender: AnyObject) {
        calipersView.stopTweaking()
    }

    override open func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .epcalipersBar
        if calipersView.isTweakingComponent {
            touchBar.defaultItemIdentifiers = [.tweak, .cancel]
            return touchBar
        }
        if !isTransparent {
            if doingMeasurement() || calipersView.isTweakingComponent {
                touchBar.defaultItemIdentifiers = [.zoom, .fixedSpaceSmall, .addCalipers]
            }
            else if imageView.image() == nil {
                touchBar.defaultItemIdentifiers = [.openFile]
            }
            else {
                touchBar.defaultItemIdentifiers = [.openFile, .fixedSpaceSmall, .zoom, .fixedSpaceSmall, .addCalipers, .fixedSpaceSmall, .calibration]
            }
        }
        else {
            if doingMeasurement() || calipersView.isTweakingComponent {
                touchBar.defaultItemIdentifiers = [.addCalipers]
            }
            else {
                touchBar.defaultItemIdentifiers = [.fixedSpaceSmall, .addCalipers, .fixedSpaceSmall, .calibration]
            }
        }
        return touchBar
    }

    public func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        // We will leave the forced unwrapped optionals here as these images have to exist, and we should crash otherwise.
        switch identifier {
        case .openFile:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let openFileImage = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil)!
            let control = NSSegmentedControl(images:[openFileImage], trackingMode: .momentary, target: self, action: #selector(openImage(_:)))
            control.segmentStyle = .separated
            customViewItem.view = control
            return customViewItem
        case NSTouchBarItem.Identifier.zoom:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let zoomInImage = NSImage(systemSymbolName: "plus.magnifyingglass", accessibilityDescription: nil)!
            let zoomOutImage = NSImage(systemSymbolName: "minus.magnifyingglass", accessibilityDescription: nil)!
            let zoomResetImage = NSImage(systemSymbolName: "1.magnifyingglass", accessibilityDescription: nil)!
            let control = NSSegmentedControl(images: [zoomInImage, zoomOutImage, zoomResetImage], trackingMode: .momentary, target: self, action: #selector(doZoom(_:)))
            control.segmentStyle = .separated
            customViewItem.view = control
            return customViewItem
        case NSTouchBarItem.Identifier.addCalipers:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let addTimeCaliperImage = NSImage(named: "custom-time-caliper")!
            let addAmplitudeCaliperImage = NSImage(named: "custom-amplitude-caliper")!
            let addAngleCaliperImage = NSImage(named: "custom-angle-caliper")!
            let control = NSSegmentedControl(images: [addTimeCaliperImage, addAmplitudeCaliperImage, addAngleCaliperImage], trackingMode: .momentary, target: self, action: #selector(addCaliper(_:)))
            control.segmentStyle = .separated
            customViewItem.view = control
            return customViewItem
        case NSTouchBarItem.Identifier.calibration:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let control = NSSegmentedControl(labels: ["Calibrate", "Clear"], trackingMode: .momentary, target: self, action: #selector(doCalibration(_:)))
            control.segmentStyle = .separated
            customViewItem.view = control
            return customViewItem
        case NSTouchBarItem.Identifier.tweak:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let images = [
                NSImage(named: "NSTouchBarGoBackTemplate")!,
                NSImage(named: "NSTouchBarGoForwardTemplate")!,
                NSImage(named: "NSTouchBarGoUpTemplate")!,
                NSImage(named: "NSTouchBarGoDownTemplate")!,
            ]
            let control = NSSegmentedControl(images: images, trackingMode: .momentary, target: self, action: #selector(tweakCaliper(_:)))
            control.segmentStyle = .separated
            customViewItem.view = control
            return customViewItem
        case NSTouchBarItem.Identifier.cancel:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            let control = NSButton(title: "Cancel", target: self, action: #selector(cancelTweak(_:)))
            customViewItem.view = control
            return customViewItem
        default:
            return nil
        }
    }
}

extension IKImageView {
    func hasImage() -> Bool {
        let size = imageSize()
        return size != .zero
    }
}
