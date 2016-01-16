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

class MainWindowController: NSWindowController {
    
    @IBOutlet weak var imageView: IKImageView!
    @IBOutlet weak var calipersView: CalipersView!
    @IBOutlet weak var toolSegmentedControl: NSSegmentedControl!
    // Note textInputView must be a strong reference to prevent deallocation
    @IBOutlet var textInputView: NSView!
    @IBOutlet weak var textField: NSTextField!
    
    var imageProperties: NSDictionary = Dictionary<String, String>()
    var imageUTType: String = ""
    var saveOptions: IKSaveOptions = IKSaveOptions()
    var imageURL: NSURL? = nil
    var firstWindowResize = true
    
    // These are taken from the Apple IKImageView demo
    let zoomInFactor: CGFloat = 1.414214
    let zoomOutFactor: CGFloat = 0.7071068
    
    let horizontalCalibration = Calibration()
    let verticalCalibration = Calibration()

    
    override var windowNibName: String? {
        return "MainWindowController"
    }
    
    override func awakeFromNib() {
        let path = NSBundle.mainBundle().pathForResource("Normal 12_Lead ECG", ofType: "jpg")
        let url = NSURL.fileURLWithPath(path!)
        imageView.setImageWithURL(url)
        imageView.editable = true
        // FIXME: need to retest combinations of these next 2 factors to see what works best
        imageView.zoomImageToFit(self)
        imageView.autoresizes = false
        imageView.currentToolMode = IKToolModeMove
        imageView.delegate = self
        // calipersView unhandled events are passed to imageView
        calipersView.nextResponder = imageView
        calipersView.imageView = imageView
        horizontalCalibration.direction = .Horizontal
        verticalCalibration.direction = .Vertical
        if NSWindowController.instancesRespondToSelector(Selector("awakeFromNib")) {
            super.awakeFromNib()
        }
    }
    
    override func windowDidLoad() {
        // Necessary to load view here or window gets resized if loaded when
        // NSAlert used.
        NSBundle.mainBundle().loadNibNamed("View", owner: self, topLevelObjects: nil)

    }
  
    func windowDidResize(notification: NSNotification) {
        // Window resizes after load, changing bounds.
        // This is the only place where first caliper can be placed with
        // accurate window bounds.
        NSLog("Window did resize")
        //imageView.autoresizes = false
        // FIXME: probably best to avoid the resizing hassle and just
        // allow user to add initial caliper manually.
//        if firstWindowResize {
//            addHorizontalCaliper()
//        }
//        firstWindowResize = false
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
            imageView.currentToolMode = IKToolModeRotate
            calipersView.lockedMode = false
        case 2:
            imageView.currentToolMode = IKToolModeNone
            calipersView.lockedMode = true
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
        case 1:
            zoomFactor = imageView.zoomFactor
            imageView.zoomFactor = zoomFactor * zoomOutFactor
        case 2:
            imageView.zoomImageToActualSize(self)
        case 3:
            imageView.zoomImageToFit(self)
        default:
            break
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

// MARK: Caliper functions
    
    func addCaliperWithDirection(direction: CaliperDirection) {
        let caliper = Caliper()
        // initiallize with Preferences here
        caliper.direction = direction
        if direction == .Horizontal {
            caliper.calibration = horizontalCalibration
        }
        else {
            caliper.calibration = verticalCalibration
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
            calibrate()
        default:
            break
        }
    }
    
    func calibrate() {

        if calipersView.calipers.count < 1 {
            showNoCalipersAlert()
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
            if horizontalCalibration.calibrationString.characters.count < 1 {
                horizontalCalibration.calibrationString = "1000 msec" // TODO: use default here
            }
            if verticalCalibration.calibrationString.characters.count < 1 {
                verticalCalibration.calibrationString = "1 mV" // TODO: use default here
            }
            let direction = c.direction
            var calibrationString: String
            if direction == .Horizontal {
                calibrationString = horizontalCalibration.calibrationString
            }
            else {
                calibrationString = verticalCalibration.calibrationString
            }
            textField.stringValue = calibrationString
            let result = alert.runModal()
            if result == NSAlertFirstButtonReturn {
                let inputText = textField.stringValue
                if inputText.characters.count > 0 {
                    calibrateWithText(inputText)
                }
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
            NSLog("Value = %f", value)
            NSLog("Units = %@", trimmedUnits)
            if value > 0 {
                let c = calipersView.activeCaliper()
                if (c == nil || c!.points() <= 0) {
                    return
                }
                var calibration: Calibration
                if c!.direction == .Horizontal {
                    calibration = horizontalCalibration
                }
                else {
                    calibration = verticalCalibration
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
    
    func showNoCalipersAlert() {
        let alert = NSAlert()
        alert.messageText = "No calipers available for calibration"
        alert.informativeText = "In order to calibrate, you must first add a caliper and then set it to a known interval, e.g. 1000 msec."
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.addButtonWithTitle("OK")
        alert.runModal()
    }
    
    func showNoCaliperSelectedAlert() {
        let alert = NSAlert()
        alert.messageText = "No caliper selected (highlighted)"
        alert.informativeText = "Select (by single-clicking it) the caliper that you want to calibrate, and then set it to a known interval, e.g. 1000 msec or 1 mV"
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.addButtonWithTitle("OK")
        alert.runModal()
    }
    
    @IBAction func clearCalibration(sender: AnyObject) {
        resetCalibration()
        calipersView.needsDisplay = true
    }
    
    func resetCalibration() {
        if horizontalCalibration.calibrated || verticalCalibration.calibrated {
            // No easy animation equivalent in Cocoa
            // flashCalipers()
            horizontalCalibration.reset()
            verticalCalibration.reset()
        }
    }
    
    
    
    
    
}
