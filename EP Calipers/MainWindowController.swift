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

// To get control over IKImageEditPanel location when opened
// When image is zoomed, double click makes panel disappear, it is somewhere off screen.
// see http://stackoverflow.com/questions/30110720/how-to-get-ikimageeditpanel-to-work-in-swift
extension IKImageView: IKImageEditPanelDataSource {
    
}

protocol QTcResultProtocol {
    func calculate(qtInSec: Double, rrInSec: Double, formula: QTcFormulaPreference,
                   convertToMsec: Bool, units: String) -> String
}

class MainWindowController: NSWindowController, NSTextFieldDelegate, CalipersViewDelegate, NSDraggingDestination {
    let appName = NSLocalizedString("EP Calipers", comment:"")
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var imageView: FixedIKImageView!
    @IBOutlet weak var calipersView: CalipersView!
    @IBOutlet weak var calipersSegementedControl: NSSegmentedControl!
    @IBOutlet weak var measurementSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var navigationSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var zoomSegmentedControl: NSSegmentedControl!

    // Note textInputView must be a strong reference to prevent deallocation
    @IBOutlet var textInputView: NSView!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet var numberInputView: NSView!
    @IBOutlet weak var numberStepper: NSStepper!
    @IBOutlet weak var numberTextField: NSTextField!
    @IBOutlet var qtcNumberInputView: NSView!
    @IBOutlet weak var qtcNumberStepper: NSStepper!
    @IBOutlet weak var qtcNumberTextField: NSTextField!
    // Preferences accessory view
    @IBOutlet var preferencesAccessoryView: NSView!
    @IBOutlet weak var caliperColorWell: NSColorWell!
    @IBOutlet weak var highlightedCaliperColorWell: NSColorWell!
    @IBOutlet weak var lineWidthSlider: NSSlider!
    @IBOutlet weak var defaultCalibrationTextField: NSTextField!
    @IBOutlet weak var defaultVerticalCalibrationTextField: NSTextField!
    @IBOutlet weak var numberOfMeanRRIntervalsTextField: NSTextField!
    @IBOutlet weak var numberOfMeanRRIntervalsStepper: NSStepper!
    @IBOutlet weak var numberOfQTcMeanRRIntervalsTextField: NSTextField!
    @IBOutlet weak var numberOfQTcMeanRRIntervalsStepper: NSStepper!
    @IBOutlet weak var showPromptsCheckBox: NSButton!
    @IBOutlet weak var transparencyCheckBox: NSButton!
    
    @IBOutlet weak var roundingPopUpButton: NSPopUpButton!
    @IBOutlet weak var formulaPopUpButton: NSPopUpButton!
    @IBOutlet weak var autoPositionTextCheckBox: NSButton!
    @IBOutlet weak var timeCaliperTextPositionPopUpButton: NSPopUpButton!
    @IBOutlet weak var amplitudeCaliperTextPositionPopUpButton: NSPopUpButton!
    
    var imageProperties: NSDictionary = Dictionary<String, String>() as NSDictionary
    var imageUTType: String = ""
    var saveOptions: IKSaveOptions = IKSaveOptions()
    var imageURL: URL? = nil
    var firstWindowResize = true
    
    var inQTcStep1 = false
    var inQTcStep2 = false
    var inCalibration = false
    var inMeanRR = false
    var rrIntervalForQTc: Double = 0.0
    
    let calipersMenuTag = 999
    let appPreferences = Preferences()
    var preferencesChanged = false
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
            // do nothing if value unchanged
            if (newValue == isTransparent) {
                return;
            }
            isTransparent = newValue
            zoomSegmentedControl.isEnabled = !isTransparent
            calipersView.lockedMode = isTransparent
            clearCalibration()
            if isTransparent {
                // Calipers sometimes leave ghosts during transition to transparent mode
                // in Mojave.
                calipersView.deleteAllCalipers()
                scrollView.drawsBackground = false
                window?.backgroundColor = NSColor.clear
                imageView.isHidden = true
                imageView.currentToolMode = IKToolModeMove
                // deal with title
                self.window?.title = appName
            }
            else {
                scrollView.drawsBackground = true
                window?.backgroundColor = NSColor.windowBackgroundColor
                imageView.isHidden = false
                imageView.currentToolMode = IKToolModeMove
                if let title = oldWindowTitle {
                    self.window?.setTitleWithRepresentedFilename(title)
                }
                else {
                    self.window?.title = appName
                }
            }
            // Need to force window display, otherwise black background sometimes drawn
            self.window?.display()
        }
    }
        
    override var windowNibName: NSNib.Name? {
        return "MainWindowController"
    }
    
    override func awakeFromNib() {
        
        // 2 lines below added for Swift 
        let NSURLPboardType = NSPasteboard.PasteboardType(rawValue: kUTTypeURL as String)
        let NSFilenamesPboardType = NSPasteboard.PasteboardType(rawValue: kUTTypeItem as String)
        let types = [NSFilenamesPboardType, NSURLPboardType, NSPasteboard.PasteboardType.tiff]
        self.window!.registerForDraggedTypes(types)
        

        
        imageView.editable = true
        // below is no longer true, open IKImageEditPanel only from menu
        imageView.doubleClickOpensImageEditPanel = false
        imageView.zoomImageToActualSize(self)
        imageView.autoresizes = false
        imageView.currentToolMode = IKToolModeMove
        imageView.delegate = self
        
        calipersView.nextResponder = scrollView
        calipersView.imageView = imageView
        calipersView.horizontalCalibration.direction = .horizontal
        calipersView.verticalCalibration.direction = .vertical
        measurementSegmentedControl.isEnabled = false
        navigationSegmentedControl.isEnabled = false
        clearMessage()
        if NSWindowController.instancesRespond(to: #selector(NSObject.awakeFromNib)) {
            super.awakeFromNib()
        }
    }
    
    override func windowDidLoad() {
        // register preference defaults
        super.windowDidLoad()
        let defaults = [
            "lineWidthKey": 2,
            "defaultCalibrationKey": "1000 msec",
            "defaultVerticalCalibrationKey": "10 mm",
            "defaultNumberOfMeanRRIntervalsKey": 3,
            "defaultNumberOfQTcMeanRRIntervalsKey": 1,
            "showPromptsKey": true,
            "roundMsecRateKey": true,
            "rounding": Rounding.ToInteger.rawValue,
            "qtcFormula": QTcFormulaPreference.Bazett.rawValue,
            "transparency": false,
            "autoPositionText": true,
            "timeCaliperTextPosition": TextPosition.centerAbove.rawValue,
            "amplitudeCaliperTextPosition": TextPosition.right.rawValue
        ] as [String : Any]
        UserDefaults.standard.register(defaults: defaults)
        appPreferences.loadPreferences()
        // need to manually register colors, using extension to NSUserDefaults
        if (appPreferences.caliperColor == nil) {
            UserDefaults.standard.setColor(NSColor.blue, forKey:"caliperColorKey")
            appPreferences.caliperColor = NSColor.blue
        }
        if (appPreferences.highlightColor == nil) {
            UserDefaults.standard.setColor(NSColor.red, forKey: "highlightColorKey")
            appPreferences.highlightColor = NSColor.red
        }
        Bundle.main.loadNibNamed("View", owner: self, topLevelObjects: nil)
        numberTextField.delegate = self
        numberOfMeanRRIntervalsTextField.delegate = self
        numberOfQTcMeanRRIntervalsTextField.delegate = self
        qtcNumberTextField.delegate = self
        
        if let path = Bundle.main.path(forResource: "Normal 12_Lead ECG", ofType: "jpg") {
                let url = URL(fileURLWithPath: path)
                self.openImageUrl(url, addToRecentDocuments: false)
        }
        // window must be non opaque for transparency to work
        self.window?.isOpaque = false
        transparent = appPreferences.transparency
        calipersView.delegate = self
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


    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(MainWindowController.doRotation(_:)) {
            return !transparent && !(calipersView.horizontalCalibration.calibrated || calipersView.verticalCalibration.calibrated)
        }
        if menuItem.action == #selector(MainWindowController.doMeasurement(_:)) {
            return calipersView.horizontalCalibration.calibrated && !calipersView.locked && !inMeanRR && !inCalibration && calipersView.horizontalCalibration.canDisplayRate
        }
        if menuItem.action == #selector(MainWindowController.addCaliper(_:)) {
            return !calipersView.locked
        }
        if menuItem.action == #selector(MainWindowController.previousPage(_:)) {
            return !transparent && imageIsPDF && pdfPageNumber > 0
        }
        if menuItem.action == #selector(MainWindowController.nextPage(_:)) {
            return !transparent && imageIsPDF && pdfPageNumber < numberOfPDFPages - 1
        }
        if menuItem.action == #selector(MainWindowController.doZoom(_:)) {
            return !transparent
        }
        if menuItem.action == #selector(openIKImageEditPanel(_:)) {
            return !transparent
        }
        if menuItem.action == #selector(openImage(_:)) {
            return !transparent
        }
        if menuItem.action == #selector(deleteAllCalipers(_:)) {
            return !calipersView.locked && !(calipersView.calipers.count < 1)
        }
        return true
    }

    // TODO: map popupbutton for text position to actual text positions, both directions
    // and add them here.
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
        if let color = appPreferences.caliperColor {
            caliperColorWell.color = color
        }
        if let color = appPreferences.highlightColor {
            highlightedCaliperColorWell.color = color
        }
        lineWidthSlider.integerValue = appPreferences.lineWidth
        if let calibration = appPreferences.defaultCalibration {
            defaultCalibrationTextField.stringValue = calibration
        }
        if let calibration = appPreferences.defaultVerticalCalibration {
            defaultVerticalCalibrationTextField.stringValue = calibration
        }
        numberOfMeanRRIntervalsTextField.integerValue = appPreferences.defaultNumberOfMeanRRIntervals
        numberOfMeanRRIntervalsStepper.integerValue = appPreferences.defaultNumberOfMeanRRIntervals
        numberOfQTcMeanRRIntervalsTextField.integerValue = appPreferences.defaultNumberOfQTcMeanRRIntervals
        numberOfQTcMeanRRIntervalsTextField.integerValue = appPreferences.defaultNumberOfQTcMeanRRIntervals
        showPromptsCheckBox.state = NSControl.StateValue(rawValue: appPreferences.showPrompts ? 1 : 0)
        transparencyCheckBox.state = NSControl.StateValue(rawValue: appPreferences.transparency ? 1 : 0)
        autoPositionTextCheckBox.state = NSControl.StateValue(rawValue: appPreferences.autoPositionText ? 1 : 0)
        formulaPopUpButton.selectItem(at: appPreferences.qtcFormula.rawValue)
        roundingPopUpButton.selectItem(at: appPreferences.rounding.rawValue)
        let result = preferencesAlert!.runModal()
        if result == NSApplication.ModalResponse.alertFirstButtonReturn {
            // assign new preferences
            appPreferences.caliperColor = caliperColorWell.color
            appPreferences.highlightColor = highlightedCaliperColorWell.color
            appPreferences.lineWidth = lineWidthSlider.integerValue
            appPreferences.defaultCalibration = defaultCalibrationTextField.stringValue
            appPreferences.defaultVerticalCalibration = defaultVerticalCalibrationTextField.stringValue
            appPreferences.defaultNumberOfMeanRRIntervals = numberOfMeanRRIntervalsStepper.integerValue
            appPreferences.defaultNumberOfQTcMeanRRIntervals = numberOfQTcMeanRRIntervalsStepper.integerValue
            appPreferences.showPrompts = showPromptsCheckBox.integerValue == 1 ? true : false
            appPreferences.transparency = transparencyCheckBox.integerValue == 1 ? true : false
            appPreferences.autoPositionText = autoPositionTextCheckBox.integerValue == 1 ? true : false
            appPreferences.timeCaliperTextPosition = timeCaliperTextPositionArray[timeCaliperTextPositionPopUpButton.indexOfSelectedItem]
            appPreferences.amplitudeCaliperTextPosition = amplitudeCaliperTextPositionArray[amplitudeCaliperTextPositionPopUpButton.indexOfSelectedItem]
            appPreferences.qtcFormula = QTcFormulaPreference(rawValue: formulaPopUpButton.indexOfSelectedItem) ?? QTcFormulaPreference.Bazett
            appPreferences.rounding = Rounding(rawValue: roundingPopUpButton.indexOfSelectedItem) ?? Rounding.ToInteger
            appPreferences.savePreferences()
            // update calipersView
            calipersView.updateCaliperPreferences(appPreferences.caliperColor, selectedColor: appPreferences.highlightColor, lineWidth: appPreferences.lineWidth, rounding: appPreferences.rounding, autoPositionText: appPreferences.autoPositionText, timeCaliperTextPosition: appPreferences.timeCaliperTextPosition, amplitudeCaliperTextPosition: appPreferences.amplitudeCaliperTextPosition)
            // update transparency
            transparent = appPreferences.transparency
            preferencesChanged = true
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
        // TODO: remove in production
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
    
    @IBAction func openIKImageEditPanel(_ sender: AnyObject) {
        let editor = IKImageEditPanel.shared()
        editor?.setFrameOrigin(NSMakePoint(400,200))
        editor?.dataSource = imageView
        editor?.makeKeyAndOrderFront(nil)
    }
    
    // Give up on Recenter after zoom
    // see IKImageView specs and
    // - (void)setImageZoomFactor:(CGFloat)zoomFactor centerPoint:(NSPoint)centerPoint
    // also could use method to get center of view's image point and use
    // - (NSPoint)convertViewPointToImagePoint:(NSPoint)viewPoint
    // to recenter image after zoom.
    // but see this too: https://lists.apple.com/archives/cocoa-dev/2008/Mar/msg00774.html
    // in Summary, setImageZoomFactor:centerPoint: doesn't work.  centerPoint doesn't affect
    // zooming, which is always recentered to the origin (lower left).
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
            zoomFactor = imageView.zoomFactor
            imageView.zoomFactor = zoomFactor * zoomInFactor
            calipersView.updateCalibration()
        case 1:
            zoomFactor = imageView.zoomFactor
            imageView.zoomFactor = zoomFactor * zoomOutFactor
            calipersView.updateCalibration()
        case 2:
            imageView.zoomImageToActualSize(self)
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
        default:
            break
        }
    }
    
    @IBAction func doNavigation(_ sender: AnyObject) {
        var navigation: Int
        if sender is NSSegmentedControl {
            navigation = sender.selectedSegment
        }
        else {
            navigation = sender.tag
        }
        if inCalibration {
            switch navigation {
            case 0:
                calibrate()
            case 1, 2:
                exitCalibration()
            default:
                break
            }
            
        }
        else if inMeanRR {
            switch navigation {
            case 0:
                meanRR()
            case 1,2:
                exitMeanRR()
            default:
                break
            }
        }
        else {  // inQTn
            switch navigation {
            case 0:
                doNextQTcStep()
            case 1:
                doPreviousQTcStep()
            case 2:
                cancelQTcSteps()
            default:
                break
            }
        }
    }
    
    @IBAction func openImage(_ sender: AnyObject) {
        /* Present open panel. */
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = validFileExtensions()
        openPanel.canSelectHiddenExtension = true
        openPanel.beginSheetModal(for: self.window!,
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
    
    func openImageUrl(_ url: URL, addToRecentDocuments: Bool) {
        // See http://cocoaintheshell.whine.fr/2012/08/kcgimagesourceshouldcache-true-default-value/
        // Default value of kCGImageSourceShouldCache depends on platform.
        // Because CGImageSourceCreateImageAtIndex can't handle PDF, we use simple method below to open image
//        let error: NSErrorPointer? = nil
        do {
            // FIXME: When run under Xcode, scrolling large images immediately after
            // they are loaded gives a crash in NSScrollWheel with message:
            // "Unexpected outstanding background CATransaction".
            // However, actual compiled program run as itself does not crash!!
            // This may be another problem with IKImageView (the Move tool also
            // no longer works with Xcode 10, Mojave), but it is not something in
            // my code.  Apparently the error message indicates that something is
            // being run on a background thread that should be on the main thread.
            // I can partially correct this my intoducing a delay in the code, but
            // it seems that the code works when compiled as stand-alone code.
            // Weird!!
            let reachable = try (url as URL).checkResourceIsReachable()
            if reachable {
                // note below can fail with bad image file and crash program
                self.imageView.setImageWith(url)
                self.imageView.zoomImageToActualSize(self)
                let urlPath = url.path
                self.oldWindowTitle = urlPath
                self.window?.setTitleWithRepresentedFilename(urlPath)
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
        let pdfData = try? Data(contentsOf: url)
        if pdfData != nil {
            if let pdf = NSPDFImageRep(data: pdfData!) {
                pdfRef = pdf
                numberOfPDFPages = pdf.pageCount
                imageIsPDF = true
                showPDFPage(pdf, page: 0)
                let urlPath = url.path
                self.window!.setTitleWithRepresentedFilename(urlPath)
                imageURL = url
                clearCalibration()
                if addToRecentDocuments {
                    NSDocumentController.shared.noteNewRecentDocumentURL(url)
                }
            }
        }
    }
    
    func showPDFPage(_ pdf: NSPDFImageRep, page: Int) {
        // consider add preference for low res, hi res (2.0, 4.0 scale?)
        let scale: CGFloat = 4.0
        pdf.currentPage = page
        var tempImage = NSImage()
        tempImage.addRepresentation(pdf)
        tempImage = scaleImage(tempImage, byFactor: scale)
        let image = nsImageToCGImage(tempImage)
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
        if let color = appPreferences.caliperColor {
            caliper.unselectedColor = color
        }
        if let color = appPreferences.highlightColor {
            caliper.selectedColor = color
        }
        caliper.color = caliper.unselectedColor
        caliper.autoPositionText = appPreferences.autoPositionText
        caliper.direction = direction
        if direction == .horizontal {
            caliper.calibration = calipersView.horizontalCalibration
            caliper.textPosition = appPreferences.timeCaliperTextPosition
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
        if let color = appPreferences.caliperColor {
            caliper.unselectedColor = color
        }
        if let color = appPreferences.highlightColor {
            caliper.selectedColor = color
        }
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
    
    @IBAction func deleteAllCalipers(_ sender: AnyObject) {
        calipersView.deleteAllCalipers()
    }
    
    func calibrateWithPossiblePrompts() {
        // not allowed to calibrate in middle of a measurement
        if calipersView.locked || inMeanRR {
            NSSound.beep()
            return
        }
        if appPreferences.showPrompts {
            if inCalibration {
                // user pressed Calibrate again instead of Next, it's OK, do what s/he wants
                calibrate()
                return
            }
            showMessage(NSLocalizedString("Use a caliper to measure a known interval, then select Next to calibrate to that interval, or Cancel.", comment:""))
            navigationSegmentedControl.isEnabled = true
            measurementSegmentedControl.isEnabled = false
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
            calibrationAlert!.informativeText = message
            if preferencesChanged {
                calipersView.horizontalCalibration.calibrationString = appPreferences.defaultCalibration!
                calipersView.verticalCalibration.calibrationString = appPreferences.defaultVerticalCalibration!
                preferencesChanged = false
            }
            else {  // don't bother doing this again if preferencesChanged
                if calipersView.horizontalCalibration.calibrationString.isEmpty {
                    calipersView.horizontalCalibration.calibrationString = appPreferences.defaultCalibration!
                }
                if calipersView.verticalCalibration.calibrationString.isEmpty {
                    calipersView.verticalCalibration.calibrationString = appPreferences.defaultVerticalCalibration!
                }
            }
            let direction = c.direction
            var calibrationString: String
            if direction == .horizontal {
                calibrationString = calipersView.horizontalCalibration.calibrationString
            }
            else {
                calibrationString = calipersView.verticalCalibration.calibrationString
            }
            textField.stringValue = calibrationString
            let result = calibrationAlert!.runModal()
            if result == NSApplication.ModalResponse.alertFirstButtonReturn {
                let inputText = textField.stringValue
                if !inputText.isEmpty {
                    calibrateWithText(inputText)
                    exitCalibration()
                }
            }
            measurementSegmentedControl.isEnabled = calipersView.horizontalCalibration.calibrated && calipersView.horizontalCalibration.canDisplayRate
        }
    }
    
    func calibrateWithText(_ inputText: String) {
        // caller must guarantee this
        assert(!inputText.isEmpty)
        var value: Double = 0.0
        var trimmedUnits: String = ""
        let scanner: Scanner = Scanner.localizedScanner(with: inputText) as! Scanner
        if scanner.scanDouble(&value) {
            let scannerString = scanner.string
            var scannerIndex = scannerString.startIndex
            scannerIndex = scannerString.index(scannerString.startIndex, offsetBy: scanner.scanLocation)
            trimmedUnits = scanner.string[scannerIndex...].trimmingCharacters(in: CharacterSet.whitespaces)
            value = fabs(value)
            if value > 0 {
                let c = calipersView.activeCaliper()
                if (c == nil || c!.points() <= 0) {
                    return
                }
                var calibration: Calibration
                if c!.direction == .horizontal {
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
                calibration.originalZoom = Double(imageView.zoomFactor)
                calibration.originalCalFactor = value / Double(c!.points())
                calibration.currentZoom = calibration.originalZoom
                calibration.calibrated = true
            }
            calipersView.needsDisplay = true
            
        }
    }
    
    func exitCalibration() {
        clearMessage()
        inCalibration = false
        navigationSegmentedControl.isEnabled = false
    }
    
    func showMessage(_ message: String) {
        calipersView.stopTweaking()
        showMessageWithoutSaving(message)
    }
    
    // This doesn't overwrite lastMessage, thus allowing multiple tweak messages that
    // will return to last pre-Tweak message when restoreLastMessage called.
    func showMessageWithoutSaving(_ message: String) {
        messageLabel.stringValue = message
    }
    
    func showMessageAndSaveLast(_ message: String) {
        lastMessage = messageLabel.stringValue
        messageLabel.stringValue = message
    }
    
    func clearMessage() {
        showMessage("")
    }
    
    func restoreLastMessage() {
        if let message = lastMessage {
            showMessageWithoutSaving(message)
        }
        else {
            clearMessage()
        }
    }
    
    func showAngleCaliperNoCalibrationAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Angle caliper", comment:"")
        alert.informativeText = NSLocalizedString("Angle calipers don't require calibration.  Only time or amplitude calipers need to be calibrated.\n\nIf you want to use an angle caliper as a Brugadometer, you must first calibrate time and amplitude calipers.", comment:"")
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
        // not allowed to do cal stuff in middle of measurement
        if calipersView.locked || inMeanRR {
            NSSound.beep()
            return
        }
        // if nothing else, clear messages
        exitCalibration()
        if calipersView.horizontalCalibration.calibrated ||
            calipersView.verticalCalibration.calibrated {
            // No easy animation equivalent in Cocoa
            // flashCalipers()
            calipersView.horizontalCalibration.reset()
            calipersView.verticalCalibration.reset()            
            measurementSegmentedControl.isEnabled = false
        }
    }
    
    func toggleIntervalRate() {
        calipersView.horizontalCalibration.displayRate = !calipersView.horizontalCalibration.displayRate
        calipersView.needsDisplay = true
    }
    
    func meanRRWithPossiblePrompts() {
        if appPreferences.showPrompts {
            if inMeanRR {
                // user pressed mRR again instead of Next, it's OK, do what s/he wants
                meanRR()
                return
            }
            showMessage(NSLocalizedString("Use a caliper to measure 2 or more intervals, then select Next to calculate mean, or Cancel.", comment:""))
            navigationSegmentedControl.isEnabled = true
            // don't allow pressing QTc button in middle of meanRR
            measurementSegmentedControl.setEnabled(false, forSegment: 2)
            inMeanRR = true
        }
        else {
            meanRR()
        }
        
    }
    
    func meanRR() {
        if noTimeCaliperExists() {
            showNoCalipersAlert(true)
            return
        }
        let singleHorizontalCaliper = getLoneTimeCaliper()
        if let caliper = singleHorizontalCaliper {
            calipersView.selectCaliper(caliper)
            calipersView.unselectCalipersExcept(caliper)
        }
        if calipersView.noCaliperIsSelected() {
            showNoTimeCaliperSelectedAlert()
            return
        }
        if let c = calipersView.activeCaliper() {
            if c.direction == .vertical {
                showNoTimeCaliperSelectedAlert()
                return
            }
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
            numberTextField.stringValue = String(appPreferences.defaultNumberOfMeanRRIntervals)
            numberStepper.integerValue = appPreferences.defaultNumberOfMeanRRIntervals
            let result = meanIntervalAlert!.runModal()
            if result == NSApplication.ModalResponse.alertFirstButtonReturn {
                if numberTextField.integerValue < 1 || numberTextField.integerValue > 10 {
                    showDivisorErrorAlert()
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
                exitMeanRR()
            }
        }
    }
    
    func exitMeanRR() {
        clearMessage()
        inMeanRR = false
        navigationSegmentedControl.isEnabled = false
        measurementSegmentedControl.setEnabled(true, forSegment: 2)
    }
    
    func calculateQTc() {
        if inQTcStep1 {
            // user pressed QTc button instead of Next.  That's OK
            doQTcStep1()
            return
        }
        if inQTcStep2 {
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
        if calipersView.noCaliperIsSelected() {
            showNoTimeCaliperSelectedAlert()
            return
        }
        if let c = calipersView.activeCaliper() {
            if c.direction == .vertical {
                showNoTimeCaliperSelectedAlert()
                return
            }
            enterQTc()
            showMessage(NSLocalizedString("Measure 1 or more RR intervals.  Select Next to continue.", comment:""))
            inQTcStep1 = true
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
                alert.addButton(withTitle: NSLocalizedString("Back", comment:""))
                alert.accessoryView = qtcNumberInputView
                qtcMeanIntervalAlert = alert
            }
            qtcNumberTextField.stringValue = String(appPreferences.defaultNumberOfQTcMeanRRIntervals)
            qtcNumberStepper.integerValue = appPreferences.defaultNumberOfQTcMeanRRIntervals
            let result = qtcMeanIntervalAlert!.runModal()
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
        }
        else {  // on error (c = nil) exit QTc
            exitQTc()
        }
    }
    
    func doQTcStep2() {
        showMessage(NSLocalizedString("Now measure QT interval and select Next, or Cancel", comment:""))
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
        navigationSegmentedControl.isEnabled = true
        // don't mess with calibration during QTc measurment
        calipersSegementedControl.isEnabled = false
        // don't allow pushing R/I or meanRR buttons either
        measurementSegmentedControl.setEnabled(false, forSegment: 0)
        measurementSegmentedControl.setEnabled(false, forSegment: 1)
        calipersView.locked = true
    }

    func exitQTc() {
        navigationSegmentedControl.isEnabled = false
        calipersSegementedControl.isEnabled = true
        measurementSegmentedControl.setEnabled(true, forSegment: 0)
        measurementSegmentedControl.setEnabled(true, forSegment: 1)
        calipersView.locked = false
        clearMessage()
        inQTcStep1 = false
        inQTcStep2 = false
    }

    func doNextQTcStep() {
        if inQTcStep1 {
            doQTcStep1()
        }
        else if inQTcStep2 {
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
        }
    }
    
}
