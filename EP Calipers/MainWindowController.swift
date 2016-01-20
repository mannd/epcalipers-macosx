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

class MainWindowController: NSWindowController, NSTextFieldDelegate {
    
    @IBOutlet weak var imageView: IKImageView!
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
    
    var imageProperties: NSDictionary = Dictionary<String, String>()
    var imageUTType: String = ""
    var saveOptions: IKSaveOptions = IKSaveOptions()
    var imageURL: NSURL? = nil
    var firstWindowResize = true
    
    var inQTcStep1 = false
    var inQTcStep2 = false
    var inCalibration = false
    var inMeanRR = false
    
    // These are taken from the Apple IKImageView demo
    let zoomInFactor: CGFloat = 1.414214
    let zoomOutFactor: CGFloat = 0.7071068
    
    // Temporary preferences, to be replaced by real ones
    let tmpPrefDefaultNumberOfMeanRRIntervals = 3
    let tmpPrefDefaultNumberOfQTcMeanRRIntervals = 1
    let tmpPrefShowPrompts = true

    
    override var windowNibName: String? {
        return "MainWindowController"
    }
    
    override func awakeFromNib() {
        let path = NSBundle.mainBundle().pathForResource("Normal 12_Lead ECG", ofType: "jpg")
        let url = NSURL.fileURLWithPath(path!)
        imageView.setImageWithURL(url)
        imageView.editable = true
        // FIXME: need to retest combinations of these next 2 factors to see what works best
        imageView.zoomImageToActualSize(self)
        imageView.autoresizes = false
        imageView.currentToolMode = IKToolModeMove
        imageView.delegate = self
        // calipersView unhandled events are passed to imageView
        calipersView.nextResponder = imageView
        calipersView.imageView = imageView
        calipersView.horizontalCalibration.direction = .Horizontal
        calipersView.verticalCalibration.direction = .Vertical
        measurementSegmentedControl.enabled = false
        navigationSegmentedControl.enabled = false
        clearMessage()
        if NSWindowController.instancesRespondToSelector(Selector("awakeFromNib")) {
            super.awakeFromNib()
        }
    }
    
    override func windowDidLoad() {
        // Necessary to load view here or window gets resized if loaded when
        // NSAlert used.
        NSBundle.mainBundle().loadNibNamed("View", owner: self, topLevelObjects: nil)
        numberTextField.delegate = self

    }

    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        if menuItem.action == Selector("doRotation:") {
            return !(calipersView.horizontalCalibration.calibrated || calipersView.verticalCalibration.calibrated)
        }
        if menuItem.action == Selector("doMeasurement:") {
            return calipersView.horizontalCalibration.calibrated
        }
        return true
    }
    
    
// MARK: Image functions
    
    @IBAction func switchToolMode(sender: AnyObject) {
        var newTool: Int
        if sender.isKindOfClass(NSSegmentedControl) {
            newTool = sender.selectedSegment
        }
        else {
            // menu items tagged
            newTool = sender.tag()
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
    
    @IBAction func doZoom(sender: AnyObject) {
        var zoom: Int
        var zoomFactor: CGFloat
        if sender.isKindOfClass(NSSegmentedControl) {
            zoom = sender.selectedSegment
        }
        else {
            zoom = sender.tag()
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
    
    @IBAction func doMeasurement(sender: AnyObject) {
        var measurement: Int
        if sender.isKindOfClass(NSSegmentedControl) {
            measurement = sender.selectedSegment
        }
        else {
            measurement = sender.tag()
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
    
    @IBAction func doNavigation(sender: AnyObject) {
        var navigation: Int
        if sender.isKindOfClass(NSSegmentedControl) {
            navigation = sender.selectedSegment
        }
        else {
            navigation = sender.tag()
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
        else {
            switch navigation {
            case 0:
                doNextStep()
            case 1:
                doPreviousStep()
            case 2:
                cancelSteps()
            default:
                break
            }
        }
    }
    
    
    @IBAction func openImage(sender: AnyObject) {
        /* Present open panel. */
        let extensions = "jpg/jpeg/JPG/JPEG/png/PNG/tiff/tif/TIFF/TIF"
        let types = extensions.componentsSeparatedByString("/")
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = types
        openPanel.canSelectHiddenExtension = true
        openPanel.beginSheetModalForWindow(self.window!,
            completionHandler: {
                (result: NSInteger) -> Void in
                if result == NSFileHandlingPanelOKButton { // User did select an image.
                    self.openImageUrl(openPanel.URL!)
                }
            }
        )
    }
    
    func openImageUrl(url: NSURL) {
        let isr = CGImageSourceCreateWithURL(url, nil)
        let options = NSDictionary(object: kCFBooleanTrue, forKey: kCGImageSourceShouldCache as String)
        let image = CGImageSourceCreateImageAtIndex(isr!, 0, options)
        if CGImageGetWidth(image) > 0 && CGImageGetHeight(image) > 0 {
            imageProperties = CGImageSourceCopyProperties(isr!, imageProperties)!
            imageView.setImage(image, imageProperties: imageProperties as [NSObject : AnyObject])
            imageView.zoomImageToFit(self)
            self.window!.setTitleWithRepresentedFilename("EP Calipers: " + url.lastPathComponent!)
            imageURL = url
        }
    }
    
// FIXME: saveImage doesn't save image effects added
    @IBAction func saveImage(sender: AnyObject) {
//        let savePanel = NSSavePanel()
//        saveOptions = IKSaveOptions(imageProperties: imageProperties as [NSObject : AnyObject], imageUTType: imageUTType)
//
//// FIXME: Accessory view doesn't work: NOTE: try nib for this
////// Option 1: build view and add it as accessory view
////        let view: NSView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
////        savePanel.accessoryView = view
////        saveOptions.addSaveOptionsToView(view)
////        // this statement doesn't work:
////        // view.autoresizingMask = CAAutoresizingMask.LayerWidthSizable | CAAutoresizingMask.LayerHeightSizable
////        
////// Option 2: add accessory view to save pane, doesn't work due to Apple bug?, even with "fix"
////        //saveOptions.addSaveOptionsAccessoryViewToSavePanel(savePanel)
////        // FIXME: http://stackoverflow.com/questions/27374355/nssavepanel-crashes-on-yosemite suggests
////        // this to avoid crash of NSSavePanel, but it doesn't work
////        //savePanel.accessoryView!.translatesAutoresizingMaskIntoConstraints = false
//
//// Option 3: forget about the accessory view:
//        savePanel.nameFieldStringValue = imageURL!.lastPathComponent!
//        savePanel.beginSheetModalForWindow(self.window!, completionHandler: {
//            (result: NSInteger) -> Void in
//            if result == NSFileHandlingPanelOKButton {
//                self.savePanelDidEnd(savePanel, returnCode: result)
//            }
//        })
    }
   
//    func savePanelDidEnd (sheet: NSSavePanel, returnCode: NSInteger) {
//        if returnCode == NSModalResponseOK {
//            let newUTType: String = saveOptions.imageUTType
//            let image: CGImage = imageView.image().takeUnretainedValue()
//            if CGImageGetWidth(image) > 0 && CGImageGetHeight(image) > 0 {
//                let url = sheet.URL
//                let dest: CGImageDestination = CGImageDestinationCreateWithURL(url!, newUTType, 1, nil)!
//                CGImageDestinationAddImage(dest, image, saveOptions.imageProperties)
//                CGImageDestinationFinalize(dest)
//            }
//            else {
//                print("*** saveImageToPath - no image")
//            }
//        }
//    }
   
// not sure we want image to zoom with window resize
//    func windowDidResize (notification: NSNotification?) {
//        imageView.zoomImageToFit(self)
//    }
    
    @IBAction func doRotation(sender: AnyObject) {
        var rotationType: Int
        if sender.isKindOfClass(NSSegmentedControl) {
            rotationType = sender.selectedSegment
        }
        else {
            rotationType = sender.tag()
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
            resetImageViewRotation()
        default:
            break
        }
        
    }
    
    func radians(degrees: Double) -> Double {
        return degrees * 3.14159265359 / 180.0
    }
    
    func rotateImageView(degrees: Double) {
        imageView.rotationAngle += CGFloat(radians(degrees))
        adjustImageAfterRotation()
    }
    
    func resetImageViewRotation() {
        imageView.rotationAngle = 0
        adjustImageAfterRotation()
    }
    
    func adjustImageAfterRotation() {
        imageView.zoomImageToActualSize(self)
    }

// MARK: Caliper functions
    
    func addCaliperWithDirection(direction: CaliperDirection) {
        let caliper = Caliper()
        // initiallize with Preferences here
        caliper.direction = direction
        if direction == .Horizontal {
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
        addCaliperWithDirection(.Horizontal)
    }
    
    func addVerticalCaliper() {
        addCaliperWithDirection(.Vertical)
    }
    
    @IBAction func addCaliper(sender: AnyObject) {
        var caliperType: Int
        if sender.isKindOfClass(NSSegmentedControl) {
            caliperType = sender.selectedSegment
        }
        else {
            caliperType = sender.tag()
        }
        switch caliperType {
        case 0:
            addHorizontalCaliper()
        case 1:
            addVerticalCaliper()
        case 2:
            calibrateWithPossiblePrompts()
        case 3:
            clearCalibration()
        default:
            break
        }
    }
    
    func calibrateWithPossiblePrompts() {
        if tmpPrefShowPrompts {
            if inCalibration {
                // user pressed Calibrate again instead of Next, it's OK, do what s/he wants
                calibrate()
                return
            }
            showMessage("Use a caliper to measure a known interval, then select Next to calibrate, or Cancel.")
            navigationSegmentedControl.enabled = true
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
            var example: String
            if c.direction == .Vertical {
                example = "1 mV"
            }
            else {
                example = "1000 msec"
            }
            let message = String(format: "Enter calibration measurement (e.g. %@)", example)
            let alert = NSAlert()
            alert.messageText = "Calibrate caliper"
            alert.informativeText = message
            alert.alertStyle = NSAlertStyle.InformationalAlertStyle
            alert.addButtonWithTitle("Calibrate")
            alert.addButtonWithTitle("Cancel")
            alert.accessoryView = textInputView
            if calipersView.horizontalCalibration.calibrationString.characters.count < 1 {
                calipersView.horizontalCalibration.calibrationString = "1000 msec" // TODO: use default here
            }
            if calipersView.verticalCalibration.calibrationString.characters.count < 1 {
                calipersView.verticalCalibration.calibrationString = "1 mV" // TODO: use default here
            }
            let direction = c.direction
            var calibrationString: String
            if direction == .Horizontal {
                calibrationString = calipersView.horizontalCalibration.calibrationString
            }
            else {
                calibrationString = calipersView.verticalCalibration.calibrationString
            }
            textField.stringValue = calibrationString
            let result = alert.runModal()
            if result == NSAlertFirstButtonReturn {
                let inputText = textField.stringValue
                if inputText.characters.count > 0 {
                    calibrateWithText(inputText)
                    exitCalibration()
                }
            }
            if calipersView.horizontalCalibration.calibrated {
                measurementSegmentedControl.enabled = true
            }
            
            
        }
    }
    
    func calibrateWithText(inputText: String) {
        // caller must guarantee this
        assert(inputText.characters.count > 0)
        var value: Double = 0.0
        var trimmedUnits: String = ""
        let scanner = NSScanner.localizedScannerWithString(inputText)
        if scanner.scanDouble(&value) {
            trimmedUnits = scanner.string!!.substringFromIndex(scanner.scanLocation).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            value = fabs(value)
            if value > 0 {
                let c = calipersView.activeCaliper()
                if (c == nil || c!.points() <= 0) {
                    return
                }
                var calibration: Calibration
                if c!.direction == .Horizontal {
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
        navigationSegmentedControl.enabled = false
    }
    
    func showMessage(message: String) {
        messageLabel.stringValue = message
    }
    
    func clearMessage() {
        showMessage("")
    }
    
    func showNoCalipersAlert(noTimeCaliper: Bool) {
        let alert = NSAlert()
        if noTimeCaliper {
            alert.messageText = "No time caliper available"
            alert.informativeText = "In order to proceed, you must first add a time caliper."
        }
        else {
            alert.messageText = "No calipers available"
            alert.informativeText = "In order to proceed, you must first add a caliper."
        }
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.addButtonWithTitle("OK")
        alert.runModal()
    }
    
    func showNoCaliperSelectedAlert() {
        let alert = NSAlert()
        alert.messageText = "No caliper selected"
        alert.informativeText = "Select (by single-clicking it) the caliper that you want to calibrate, and then set it to a known interval, e.g. 1000 msec or 1 mV"
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.addButtonWithTitle("OK")
        alert.runModal()
    }
    
    func showNoTimeCaliperSelectedAlert() {
        let alert = NSAlert()
        alert.messageText = "No time caliper selected"
        alert.informativeText = "Select a time caliper.  Stretch the caliper over several intervals to get an average interval and rate."
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.addButtonWithTitle("OK")
        alert.runModal()
    }
    
    func showDivisorErrorAlert() {
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.WarningAlertStyle
        alert.messageText = "Bad number of intervals"
        alert.informativeText = "Please enter a number between 1 and 10"
        alert.addButtonWithTitle("OK")
        alert.runModal()
    }
    
    func showMeanRRResultAlert(meanInterval: Double, meanRate: Double, intervalUnits: String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.messageText = "Mean interval and rate"
        alert.informativeText = String(format: "Mean interval = %.4g %@\nMean rate = %.4g bpm", meanInterval, intervalUnits, meanRate)
        alert.addButtonWithTitle("OK")
        alert.runModal()
    }

    
    func clearCalibration() {
        resetCalibration()
        calipersView.needsDisplay = true
    }
    
    func resetCalibration() {
        // if nothing else, clear messages
        exitCalibration()
        if calipersView.horizontalCalibration.calibrated ||
            calipersView.verticalCalibration.calibrated {
            // No easy animation equivalent in Cocoa
            // flashCalipers()
            calipersView.horizontalCalibration.reset()
            calipersView.verticalCalibration.reset()            
            measurementSegmentedControl.enabled = false
        }
    }
    
    func toggleIntervalRate() {
        calipersView.horizontalCalibration.displayRate = !calipersView.horizontalCalibration.displayRate
        calipersView.needsDisplay = true
    }
    
    func meanRRWithPossiblePrompts() {
        if tmpPrefShowPrompts {
            if inMeanRR {
                // user pressed mRR again instead of Next, it's OK, do what s/he wants
                meanRR()
                return
            }
            showMessage("Use a caliper to measure 2 or more intervals, then select Next to continue, or Cancel.")
            navigationSegmentedControl.enabled = true
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
            if c.direction == .Vertical {
                showNoTimeCaliperSelectedAlert()
                return
            }
            
            let alert = NSAlert()
            alert.messageText = "Enter number of intervals"
            alert.informativeText = "How many intervals is this caliper measuring?  "
            alert.alertStyle = NSAlertStyle.InformationalAlertStyle
            alert.addButtonWithTitle("Calculate")
            alert.addButtonWithTitle("Cancel")
            alert.accessoryView = numberInputView
            // TODO: get numberTextField and stepper value from Preferences
            numberTextField.stringValue = String(tmpPrefDefaultNumberOfMeanRRIntervals)
            numberStepper.integerValue = tmpPrefDefaultNumberOfMeanRRIntervals
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
        navigationSegmentedControl.enabled = false
    }
    
    func calculateQTc() {
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
            if c.direction == .Vertical {
                showNoTimeCaliperSelectedAlert()
                return
            }
            // TODO: wrap up entry and exit steps in funcs for QT
            enterQTc()
            showMessage("Measure 1 or more RR intervals.  Select Next to continue.")
            inQTcStep1 = true
        }
        
    }
    
    func doQTcStep1() {
        if let c = calipersView.activeCaliper() {
            let alert = NSAlert()
            alert.alertStyle = .InformationalAlertStyle
            alert.messageText = "QTc step 1: RR interval: Enter number of intervals"
            alert.informativeText = "How many RR intervals is this caliper measuring?"
            alert.addButtonWithTitle("Calculate")
            alert.addButtonWithTitle("Cancel")
            alert.accessoryView = numberInputView
            // TODO: replace with Preference value
            numberTextField.stringValue = String(tmpPrefDefaultNumberOfQTcMeanRRIntervals)
            numberStepper.integerValue = tmpPrefDefaultNumberOfQTcMeanRRIntervals
            let result = alert.runModal()
            if result == NSAlertFirstButtonReturn {
                NSLog("Finish QTc step 1")
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
                let rrIntervalForQTc = c.intervalInSecs(meanInterval)
                // now measure QT...
                inQTcStep1 = false
                inQTcStep2 = true
            }
        }
        else {
            exitQTc()
        }
    }

    func enterQTc() {
        navigationSegmentedControl.enabled = true
        calipersView.locked = true
    }

    func exitQTc() {
        navigationSegmentedControl.enabled = false
        calipersView.locked = false
        clearMessage()
        inQTcStep1 = false
        inQTcStep2 = false
    }

    func doNextStep() {
        if inQTcStep1 {
            doQTcStep1()
        }
    }

    func doPreviousStep() {
        if inQTcStep1 {
            NSLog("Back from QTc step 2")
            exitQTc()
        }
        
    }

    func cancelSteps() {
        NSLog("Cancel QTc")
        exitQTc()
    }

    func getLoneTimeCaliper() -> Caliper? {
        var c: Caliper? = nil
        var n: Int = 0
        if calipersView.calipers.count > 0 {
            for caliper in calipersView.calipers {
                if caliper.direction == .Horizontal {
                    c = caliper
                    n++
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
            if c.direction == .Horizontal {
                noTimeCaliperFound = false
            }
        }
        return noTimeCaliperFound
    }
    
    @IBAction func stepperAction(sender: AnyObject) {
        numberTextField.integerValue = numberStepper.integerValue
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        if obj.name == "NSControlTextDidChangeNotification" {
            if obj.object === numberTextField {
                numberStepper.integerValue = numberTextField.integerValue
            }
        }
    }
}
