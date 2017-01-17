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

class MainWindowController: NSWindowController, NSTextFieldDelegate {
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var imageView: FixedIKImageView!
    @IBOutlet weak var calipersView: CalipersView!
    @IBOutlet weak var toolSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var calipersSegementedControl: NSSegmentedControl!
    @IBOutlet weak var measurementSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var navigationSegmentedControl: NSSegmentedControl!
    
    // Note textInputView must be a strong reference to prevent deallocation
    @IBOutlet var textInputView: NSView!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet var numberInputView: NSView!
    @IBOutlet weak var numberStepper: NSStepper!
    @IBOutlet weak var numberTextField: NSTextField!
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
    @IBOutlet weak var roundMsecRateCheckBox: NSButton!

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
        
    override var windowNibName: String? {
        return "MainWindowController"
    }
    
    override func awakeFromNib() {
        
//        [self.window registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        let types = [NSFilenamesPboardType, NSURLPboardType, NSPasteboardTypeTIFF]
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
            "roundMsecRateKey": true
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
        
        if let path = Bundle.main.path(forResource: "Normal 12_Lead ECG", ofType: "jpg") {
                let url = URL(fileURLWithPath: path)
                self.openImageUrl(url, addToRecentDocuments: false)
        }
    }
    
    func draggingEntered(_ sender: NSDraggingInfo!) -> NSDragOperation  {
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
    
    func performDragOperation(_ sender: NSDraggingInfo!) -> Bool {
        if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            if let imagePath = board[0] as? String {
                let url = URL(fileURLWithPath: imagePath)
                openURL(url, addToRecentDocuments: true)
                return true
            }
        }
        return false    }
    
    func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        if let board = drag.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray,
            let path = board[0] as? String {
            let url = URL(fileURLWithPath: path)
            let suffix = url.pathExtension
            for ext in validFileExtensions() {
                if ext.lowercased() == suffix {
                    return true
                }
            }
            
        }
        return false
    }


    func validate(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(MainWindowController.doRotation(_:)) {
            return !(calipersView.horizontalCalibration.calibrated || calipersView.verticalCalibration.calibrated)
        }
        if menuItem.action == #selector(MainWindowController.doMeasurement(_:)) {
            return calipersView.horizontalCalibration.calibrated && !calipersView.locked && !inMeanRR && !inCalibration && calipersView.horizontalCalibration.canDisplayRate
        }
        if menuItem.action == #selector(MainWindowController.addCaliper(_:)) {
            return !calipersView.locked
        }
        if menuItem.action == #selector(MainWindowController.previousPage(_:)) {
            return imageIsPDF && pdfPageNumber > 0
        }
        if menuItem.action == #selector(MainWindowController.nextPage(_:)) {
            return imageIsPDF && pdfPageNumber < numberOfPDFPages - 1
        }
        return true
    }
    
    @IBAction func showPreferences(_ sender: AnyObject) {
        // preferencesAlert must be a persistent variable, or else values disappear from textfields with tabbing.
        // See http://stackoverflow.com/questions/14615094/nstextfield-text-disappears-sometimes
        // Note there is an autolayout bug here, probable introduced in macOS 10.12
        // see http://openradar.appspot.com/28700495
        if preferencesAlert == nil {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "EP Calipers preferences"
            	alert.accessoryView = preferencesAccessoryView
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            preferencesAlert = alert
        }
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
        showPromptsCheckBox.state = appPreferences.showPrompts ? 1 : 0
        roundMsecRateCheckBox.state = appPreferences.roundMsecRate ? 1 : 0
        let result = preferencesAlert!.runModal()
        if result == NSAlertFirstButtonReturn {
            // assign new preferences
            appPreferences.caliperColor = caliperColorWell.color
            appPreferences.highlightColor = highlightedCaliperColorWell.color
            appPreferences.lineWidth = lineWidthSlider.integerValue
            appPreferences.defaultCalibration = defaultCalibrationTextField.stringValue
            appPreferences.defaultVerticalCalibration = defaultVerticalCalibrationTextField.stringValue
            appPreferences.defaultNumberOfMeanRRIntervals = numberOfMeanRRIntervalsStepper.integerValue
            appPreferences.defaultNumberOfQTcMeanRRIntervals = numberOfQTcMeanRRIntervalsStepper.integerValue
            appPreferences.showPrompts = showPromptsCheckBox.integerValue == 1 ? true : false
            appPreferences.roundMsecRate = roundMsecRateCheckBox.integerValue == 1 ? true : false
            appPreferences.savePreferences()
            // update calipersView
            calipersView.updateCaliperPreferences(appPreferences.caliperColor, selectedColor: appPreferences.highlightColor, lineWidth: appPreferences.lineWidth, roundMsecRate: appPreferences.roundMsecRate)
            preferencesChanged = true
        }
    }
    
    @IBAction func numberOfMeanRRStepperAction(_ sender: AnyObject) {
        numberOfMeanRRIntervalsTextField.integerValue = numberOfMeanRRIntervalsStepper.integerValue
    }
    
    @IBAction func numberOfQTcMeanRRStepperAction(_ sender: AnyObject) {
        numberOfQTcMeanRRIntervalsTextField.integerValue = numberOfQTcMeanRRIntervalsStepper.integerValue
    }
    
    
    
    @IBAction func switchToolMode(_ sender: AnyObject) {
        // consider updating menuitmes with checks when switching tools
        var newTool: Int
        if sender is NSSegmentedControl {
            newTool = sender.selectedSegment
        }
        else {
            // menu items tagged
            newTool = sender.tag
            // also make segmented control match selected tool
            toolSegmentedControl.selectedSegment = newTool
        }
        switch newTool {
        case 0:
            imageView.currentToolMode = IKToolModeMove
            calipersView.lockedMode = false
        case 1:
            imageView.currentToolMode = IKToolModeNone
            calipersView.lockedMode = false
        default:
            break
        }
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
                (result: NSInteger) -> Void in
                if result == NSFileHandlingPanelOKButton {
                    self.openURL(openPanel.url, addToRecentDocuments: true)
               }
            }
        )
    }
    
    func validFileExtensions() -> [String] {
        let extensions = "jpg/jpeg/JPG/JPEG/png/PNG/tiff/tif/TIFF/TIF/pdf/PDF"
        return extensions.components(separatedBy: "/")
    }
    
    func openURL(_ url: URL?, addToRecentDocuments: Bool) {
        if let goodURL = url {
            clearPDF()
            if isPDFFile((goodURL as NSURL).filePathURL) {
                openPDF(goodURL, addToRecentDocuments: addToRecentDocuments)
            }
            else {
                openImageUrl(goodURL, addToRecentDocuments: addToRecentDocuments)
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
            let reachable = try (url as URL).checkResourceIsReachable()
            if reachable {
                imageView.setImageWith(url)
                imageView.zoomImageToActualSize(self)
                let urlPath = url.path
                self.window!.setTitleWithRepresentedFilename(urlPath)
                
//                else {
//                    self.window!.title = "EP Calipers"
//                }
                imageURL = url
                clearCalibration()
                if addToRecentDocuments {
                    NSDocumentController.shared().noteNewRecentDocumentURL(url)
                }
            }
            else {
               throw OpenError.Nonspecific
            }
        }
        catch _ {
            let alert = NSAlert()
            alert.messageText = "File not opened"
            alert.informativeText = "Can't open \(url)"
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
    
    @IBAction func saveImage(_ sender: AnyObject) {
        // Save image for now is just uses the system screenshot utility
        if !calipersView.takeScreenshot() {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Screenshot cancelled"
            alert.informativeText = "Screenshot cancelled by user.  This message may also appear if there is a problem taking a screenshot on your machine."
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
                    NSDocumentController.shared().noteNewRecentDocumentURL(url)
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
        NSLog("Rotate")
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
        caliper.roundMsecRate = appPreferences.roundMsecRate
        if let color = appPreferences.caliperColor {
            caliper.unselectedColor = color
        }
        if let color = appPreferences.highlightColor {
            caliper.selectedColor = color
        }
        caliper.color = caliper.unselectedColor
        caliper.direction = direction
        if direction == .horizontal {
            caliper.calibration = calipersView.horizontalCalibration
        }
        else {
            caliper.calibration = calipersView.verticalCalibration
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
        caliper.direction = .horizontal
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
    
    func calibrateWithPossiblePrompts() {
        // not allowed to calibrate in middle of a measurement
        if calipersView.locked || inMeanRR {
            NSBeep()
            return
        }
        if appPreferences.showPrompts {
            if inCalibration {
                // user pressed Calibrate again instead of Next, it's OK, do what s/he wants
                calibrate()
                return
            }
            showMessage("Use a caliper to measure a known interval, then select Next to calibrate to that interval, or Cancel.")
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
                example = "1 mV"
            }
            else {
                example = "1000 msec"
            }
            let message = String("Enter calibration measurement (e.g. \(example))")!
            if calibrationAlert == nil {
            let alert = NSAlert()
                alert.messageText = "Calibrate caliper"
                //alert.informativeText = message
                alert.alertStyle = NSAlertStyle.informational
                alert.addButton(withTitle: "Calibrate")
                alert.addButton(withTitle: "Cancel")
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
            if result == NSAlertFirstButtonReturn {
                let inputText = textField.stringValue
                if inputText.characters.count > 0 {
                    calibrateWithText(inputText)
                    exitCalibration()
                }
            }
            measurementSegmentedControl.isEnabled = calipersView.horizontalCalibration.calibrated && calipersView.horizontalCalibration.canDisplayRate
        }
    }
    
    func calibrateWithText(_ inputText: String) {
        // caller must guarantee this
        assert(inputText.characters.count > 0)
        var value: Double = 0.0
        var trimmedUnits: String = ""
        let scanner: Scanner = Scanner.localizedScanner(with: inputText) as! Scanner
        if scanner.scanDouble(&value) {
            let scannerString = scanner.string
            var scannerIndex = scannerString.startIndex
            scannerIndex = scannerString.index(scannerString.startIndex, offsetBy: scanner.scanLocation)
            trimmedUnits = scanner.string.substring(from: scannerIndex).trimmingCharacters(in: CharacterSet.whitespaces)
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
        messageLabel.stringValue = message
    }
    
    func clearMessage() {
        showMessage("")
    }
    
    func showAngleCaliperNoCalibrationAlert() {
        let alert = NSAlert()
        alert.messageText = "Angle caliper"
        alert.informativeText = "Angle calipers don't require calibration.  Only time or amplitude calipers need to be calibrated.\n\nIf you want to use an angle caliper as a Brugadometer, you must first calibrate time and amplitude calipers."
        alert.alertStyle = NSAlertStyle.informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showNoCalipersAlert(_ noTimeCaliper: Bool) {
        let alert = NSAlert()
        if noTimeCaliper {
            alert.messageText = "No time caliper available"
            alert.informativeText = "In order to proceed, you must first add a time caliper."
        }
        else {
            alert.messageText = "No calipers available"
            alert.informativeText = "In order to proceed, you must first add a caliper."
        }
        alert.alertStyle = NSAlertStyle.informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showNoCaliperSelectedAlert() {
        let alert = NSAlert()
        alert.messageText = "No caliper selected"
        alert.informativeText = "Select (by single-clicking it) the caliper that you want to calibrate, and then set it to a known interval, e.g. 1000 msec or 1 mV"
        alert.alertStyle = NSAlertStyle.informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showNoTimeCaliperSelectedAlert() {
        let alert = NSAlert()
        alert.messageText = "No time caliper selected"
        alert.informativeText = "Select a time caliper.  Stretch the caliper over several intervals to get an average interval and rate."
        alert.alertStyle = NSAlertStyle.informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showDivisorErrorAlert() {
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.warning
        alert.messageText = "Bad number of intervals"
        alert.informativeText = "Please enter a number between 1 and 10"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showMeanRRResultAlert(_ meanInterval: Double, meanRate: Double, intervalUnits: String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.informational
        alert.messageText = "Mean interval and rate"
        alert.informativeText = String(format: "Mean interval = %.4g %@\nMean rate = %.4g bpm", meanInterval, intervalUnits, meanRate)
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    
    func clearCalibration() {
        resetCalibration()
        calipersView.needsDisplay = true
    }
    
    func resetCalibration() {
        // not allowed to do cal stuff in middle of measurement
        if calipersView.locked || inMeanRR {
            NSBeep()
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
            showMessage("Use a caliper to measure 2 or more intervals, then select Next to calculate mean, or Cancel.")
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
            
            let alert = NSAlert()
            alert.messageText = "Enter number of intervals"
            alert.informativeText = "How many intervals is this caliper measuring?  "
            alert.alertStyle = NSAlertStyle.informational
            alert.addButton(withTitle: "Calculate")
            alert.addButton(withTitle: "Cancel")
            alert.accessoryView = numberInputView
            numberTextField.stringValue = String(appPreferences.defaultNumberOfMeanRRIntervals)
            numberStepper.integerValue = appPreferences.defaultNumberOfMeanRRIntervals
            let result = alert.runModal()
            if result == NSAlertFirstButtonReturn {
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
            showMessage("Measure 1 or more RR intervals.  Select Next to continue.")
            inQTcStep1 = true
        }
        
    }
    
    func doQTcStep1() {
        if let c = calipersView.activeCaliper() {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "QTc: Enter number of RR intervals"
            alert.informativeText = "How many RR intervals is this caliper measuring?"
            alert.addButton(withTitle: "Continue")
            alert.addButton(withTitle: "Back")
            alert.accessoryView = numberInputView
            numberTextField.stringValue = String(appPreferences.defaultNumberOfQTcMeanRRIntervals)
            numberStepper.integerValue = appPreferences.defaultNumberOfQTcMeanRRIntervals
            let result = alert.runModal()
            if result == NSAlertFirstButtonReturn {
                if numberTextField.integerValue < 1 || numberTextField.integerValue > 10 {
                    showDivisorErrorAlert()
                    exitQTc()
                    return
                }
                // get integer from the stepper
                let divisor = numberStepper.integerValue
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
        showMessage("Now measure QT interval and select Next, or Cancel")
    }
    
    func doQTcResult() {
        if let c = calipersView.activeCaliper() {
            var qt = fabs(c.intervalInSecs(c.intervalResult()))
            var meanRR = fabs(rrIntervalForQTc)
            var result = "Invalid Result"
            if meanRR > 0 {
                let sqrtRR = sqrt(meanRR)
                var qtc = qt / sqrtRR
                // switch to units that calibration uses
                if c.calibration.unitsAreMsec {
                    meanRR *= 1000
                    qt *= 1000
                    qtc *= 1000
                }
                result = String(format: "Mean RR = %.4g %@\nQT = %.4g %@\nQTc = %.4g %@\n(Bazett's formula)", meanRR, c.calibration.units, qt, c.calibration.units, qtc, c.calibration.units)
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = "Calculated QTc"
                alert.informativeText = result
                alert.addButton(withTitle: "OK")
                alert.runModal()
                exitQTc()
            }
        }
        else { // c shouldn't = nil, but if it does
            exitQTc()
        }
        
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
                if caliper.direction == .horizontal {
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
    }
    
    override func controlTextDidChange(_ obj: Notification) {
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
        }
    }
    
}
