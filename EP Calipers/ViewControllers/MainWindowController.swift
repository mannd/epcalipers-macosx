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
import UniformTypeIdentifiers

protocol QTcResultProtocol {
    func calculate(qtInSec: Double, rrInSec: Double, formula: QTcFormulaPreference,
                   convertToMsec: Bool, units: String) -> String
}

class MainWindowController: NSWindowController, NSTextFieldDelegate, CalipersViewDelegate, NSDraggingDestination, NSMenuItemValidation, NSToolbarDelegate, NSToolbarItemValidation {

    
    let appName = NSLocalizedString("EP Calipers", comment:"")

    @IBOutlet weak var toolbar: NSToolbar!

    @IBOutlet weak var mainView: MainView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var imageView: IKImageView!
    @IBOutlet weak var calipersView: CalipersView!
    @IBOutlet var welcomeView: NSView!

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

    // Welcome screen
    @IBOutlet weak var welcomeImageButton: NSButton!
    @IBOutlet weak var welcomeTransparentButton: NSButton!
    @IBOutlet weak var welcomeSettingsButton: NSButton!
    @IBOutlet weak var welcomeHelpButton: NSButton!

    @IBOutlet weak var calipersViewTrailingContraint: NSLayoutConstraint!
    @IBOutlet weak var calipersViewBottomConstraint: NSLayoutConstraint!

    private weak var calibrationCustomTextField: NSTextField?

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
    var inQTc: Bool {
        inQTcStep1 || inQTcStep2
    }

    var readyToMeasure: Bool {
        calipersView.horizontalCalibration.calibrated && calipersView.horizontalCalibration.canDisplayRate && (hasImage() || isTransparent)
    }

    var inMeasurement: Bool {
        inQTc || calipersView.isTweakingComponent
        || (appPreferences.showPrompts && inCalibration)
        || (appPreferences.showPrompts && inMeanRR)
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
    let appPreferences = Preferences.shared
    var preferencesAlert: NSAlert? = nil
    var meanIntervalAlert: NSAlert? = nil
    var qtcMeanIntervalAlert: NSAlert? = nil
    private var calibrationRadioButtons: [NSButton] = []

    private struct CalibrationOption {
        let title: String
        let value: String
    }

    private struct CalibrationAccessory {
        let view: NSView
        let customTextField: NSTextField
        let customRadioButton: NSButton
        let optionButtons: [NSButton]
        let options: [CalibrationOption]

        var inputText: String {
            if customRadioButton.state == .on {
                return customTextField.stringValue
            }

            for (index, button) in optionButtons.enumerated() {
                if button.state == .on {
                    return options[index].value
                }
            }

            return customTextField.stringValue
        }

        var buttonChosen: Int {
            if customRadioButton.state == .on {
                return 0
            }

            for (index, button) in optionButtons.enumerated() {
                if button.state == .on {
                    return index + 1
                }
            }

            return 0

        }
    }
    
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
            calipersView.setNotesHidden(true)
            scrollView.drawsBackground = false
            scrollView.hasVerticalScroller = false
            scrollView.hasHorizontalScroller = false
            window?.backgroundColor = NSColor.clear
            window?.hasShadow = false
            imageView.isHidden = true
            hideWelcomeView()
            self.window?.title = appName
        }
        else {
            scrollView.drawsBackground = true
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = true
            calipersView.setNotesHidden(false)
            window?.backgroundColor = NSColor.windowBackgroundColor
            window?.hasShadow = true
            imageView.isHidden = false
            if !imageView.hasImage() {
                showWelcomeView()
            }
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
        let NSURLPboardType = NSPasteboard.PasteboardType(rawValue: UTType.url.identifier)
        let NSFilenamesPboardType = NSPasteboard.PasteboardType(rawValue: UTType.item.identifier)
        let types = [NSFilenamesPboardType, NSURLPboardType, NSPasteboard.PasteboardType.tiff]
        self.window?.registerForDraggedTypes(types)

        imageView.editable = true
        imageView.doubleClickOpensImageEditPanel = false // EditPanel broken in newest macOS versions
        //imageView.zoomImageToActualSize(self)
        zoomImageViewToLogicalActualSize()
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
        
        appPreferences.load()

        Bundle.main.loadNibNamed("View", owner: self, topLevelObjects: nil)
        numberTextField.delegate = self
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

        calipersView.noteTextColor = appPreferences.noteTextColor
        calipersView.noteFontSize = CGFloat(appPreferences.noteTextFontSize)
        calipersView.noteSize = NSSize(width: CGFloat(appPreferences.noteTextBoxWidth), height: CGFloat(appPreferences.noteTextBoxHeight))

        calipersView.caliperTextFontSize = CGFloat(appPreferences.caliperTextFontSize)

        // NOTE: Concurrent drawing stays disabled because the view's drawing path is not guaranteed to be thread-safe.  So we don't want to set calipersView.canDrawConcurrently to true (it is false by default).

        instructionPanel.setIsVisible(false)
        instructionPanel.becomesKeyOnlyIfNeeded = true

        // Need to style Welcome Screen buttons before loading the screen.
        let welcomeButtons = [welcomeImageButton, welcomeTransparentButton, welcomeSettingsButton, welcomeHelpButton]
        for button in welcomeButtons {
            styleWelcomeLinkButton(button)
        }

        // style Welcome Screen buttons, then show screen
        if !isTransparent && !imageView.hasImage() {
            print("Welcome screen: showing")
            // load welcome screen here
            showWelcomeView()
        }

        toolbar.delegate = self

        scrollView.postsFrameChangedNotifications = true
        scrollView.contentView.postsBoundsChangedNotifications = true;

        NotificationCenter.default.addObserver(self, selector:#selector(imageBoundsDidChange), name: NSView.boundsDidChangeNotification, object:scrollView.contentView)
        NotificationCenter.default.addObserver(self, selector:#selector(imageFrameDidChange), name:NSView.frameDidChangeNotification, object:scrollView.contentView)
        NotificationCenter.default.addObserver(self, selector: #selector(scrollBarsDidChange), name: NSScroller.preferredScrollerStyleDidChangeNotification, object: nil)

        // for debugging
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(windowDidResizeNotification(_:)),
//            name: NSWindow.didResizeNotification,
//            object: window
//        )
    }

    // for debugging window size
//    @objc private func windowDidResizeNotification(_ notification: Notification) {
//        guard let window else { return }
//
//        print("Content size: \(window.contentView?.bounds.size ?? .zero)")
//    }

    private func showWelcomeView() {
        guard welcomeView.superview == nil else { return }

        welcomeView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(welcomeView, positioned: .above, relativeTo: calipersView)

        NSLayoutConstraint.activate([
            welcomeView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            welcomeView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            welcomeView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            welcomeView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
    }

    private func hideWelcomeView() {
        welcomeView.removeFromSuperview()
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

    private func styleWelcomeLinkButton(_ button: NSButton?) {
        guard let button else { return }
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.linkColor,
            .font: NSFont.systemFont(ofSize: 18)
        ]

        button.attributedTitle = NSAttributedString(
            string: button.title,
            attributes: attributes
        )
        button.isBordered = false
        button.alignment = .left
        //button.cursor = .pointingHand
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
        if toolbarItem.itemIdentifier.rawValue == "newFileToolbar" {
            if let control = toolbarItem.view as? NSSegmentedControl {
                control.setEnabled(true, forSegment: 0)
                control.setEnabled(!transparent, forSegment: 1)
            }
            return true
        }
        if toolbarItem.action == #selector(saveImage(_:)) {
            return !transparent
        }
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
            if let control = toolbarItem.view as? NSSegmentedControl {
                control.setEnabled(readyToMeasure, forSegment: 0)
                control.setEnabled(readyToMeasure, forSegment: 1)
                control.setEnabled(readyToMeasure, forSegment: 2)
                control.setEnabled(inMeasurement, forSegment: 3)
            }
        }
        return true
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(saveImage(_:)) {
            return !transparent
        }
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
        if menuItem.action == #selector(deleteAllNotes(_:)) {
            return calipersView.hasNotes
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

    @IBAction func showHelp(_ sender: AnyObject) {
        NSApplication.shared.showHelp(sender)
    }

    @IBAction func showPreferences(_ sender: AnyObject) {
        let controller = SettingsViewController(mainWindowController: self)
        controller.showModalWindow()
        return;
    }

    func settingsDidChange(previousTransparency: Bool) {
        calipersView.updateCaliperPreferences()
        calipersView.updateDefaultCalibrationStrings(horizontal: appPreferences.defaultHorizontalCalibration,
                                                     vertical: appPreferences.defaultVerticalCalibration)

        // Updating transparency has side effects, so only route through the property when it changed.
        if previousTransparency != appPreferences.transparency {
            transparent = appPreferences.transparency
        }
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
            calipersView.updateCalibration()
        case 1:
            zoomFactor = scrollView.magnification
            scrollView.magnification = scrollView.magnification * zoomOutFactor
            calipersView.updateCalibration()
        case 2:
            scrollView.magnification = 1.0
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
        openPanel.allowedContentTypes = validFileContentTypes()
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

    func validFileContentTypes() -> [UTType] {
        validFileExtensions().compactMap { UTType(filenameExtension: $0) }
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
            hideWelcomeView()
            hideWelcomeView()
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment:""))
            let result = alert.runModal()
            if result == NSApplication.ModalResponse.alertFirstButtonReturn {
                transparent = false
                appPreferences.transparency = transparent
                appPreferences.save()
            }
            else {
                return
            }
        }
        if let goodURL = url {
            calipersView.deleteAllNotes()
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


    @IBAction func doFile(_ sender: AnyObject) {
        print("doFile")
        let tag: Int
        if sender is NSSegmentedControl {
            tag = sender.selectedSegment
        }
        else {
            tag = sender.tag
        }
        print("tag = \(tag)")
        switch tag {
        case 0:
            openImage(sender)
        case 1:
            saveImage(sender)
        default:
            break
        }

    }

    func openImageUrl(_ url: URL, addToRecentDocuments: Bool, isSampleECG: Bool = false) {
        // See http://cocoaintheshell.whine.fr/2012/08/kcgimagesourceshouldcache-true-default-value/
        do {
            let reachable = try (url as URL).checkResourceIsReachable()
            // Setting imageview with url, as in imageView.setImage(url:) can crash program,
            // if you are loading a large image and then try to scroll it.  Must load as below.
            if reachable, let data = NSData(contentsOf: url), let image = NSImage(data: data as Data) {
                self.imageView.setImage(image.cgImage(forProposedRect: nil, context: nil, hints: nil), imageProperties: nil)
                //self.imageView.zoomImageToActualSize(self)
                zoomImageViewToLogicalActualSize()
                let urlPath = url.path
                if !isSampleECG {
                    // We just use app name when showing sample ECG
                    self.oldWindowTitle = urlPath
                    self.window?.setTitleWithRepresentedFilename(urlPath)
                }
                self.imageURL = url
                hideWelcomeView()
                self.clearCalibration()
                scrollView.magnification = 1.0
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
    
    @IBAction func saveImage(_ sender: AnyObject) {
        guard let window = self.window,
              let imageData = captureContentViewAsPNG(),
              let contentView = window.contentView else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = NSLocalizedString("Screenshot failed", comment: "")
            alert.informativeText = NSLocalizedString("Unable to capture the window contents.", comment: "")
            alert.runModal()
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = defaultScreenshotFileName()
        savePanel.beginSheetModal(for: window) { result in
            guard result == .OK, let url = savePanel.url else { return }
            do {
                try imageData.write(to: url)
            } catch {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = NSLocalizedString("Screenshot not saved", comment: "")
                alert.informativeText = NSLocalizedString("The screenshot could not be written to disk.", comment: "")
                alert.beginSheetModal(for: window, completionHandler: nil)
            }
            contentView.needsDisplay = true
        }
    }

    private func captureContentViewAsPNG() -> Data? {
        guard let window = self.window, let contentView = window.contentView else { return nil }
        let bounds = contentView.bounds
        guard let bitmap = contentView.bitmapImageRepForCachingDisplay(in: bounds) else { return nil }

        contentView.cacheDisplay(in: bounds, to: bitmap)
        return bitmap.representation(using: .png, properties: [:])
    }

    private func defaultScreenshotFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return "EP Calipers Screenshot \(formatter.string(from: Date())).png"
    }

    // see http://stackoverflow.com/questions/15246563/extract-nsimage-from-pdfpage-with-varying-resolution?rq=1 and http://stackoverflow.com/questions/1897019/convert-pdf-pages-to-images-with-cocoa
    func openPDF(_ url: URL, addToRecentDocuments: Bool) {
        do {
            if let pdfData = try? Data(contentsOf: url), let pdf = NSPDFImageRep(data: pdfData) {
                pdfRef = pdf
                numberOfPDFPages = pdf.pageCount
                imageIsPDF = true
                showPDFPage(pdf, page: 0, preserveRotation: false)
                hideWelcomeView()
                let urlPath = url.path
                self.oldWindowTitle = urlPath
                self.window?.setTitleWithRepresentedFilename(urlPath)
                imageURL = url
                clearCalibration()
                // New PDF files reset magnification to 1.0.
                scrollView.magnification = 1.0
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

    func showPDFPage(_ pdf: NSPDFImageRep, page: Int, preserveRotation: Bool = true) {
        let scale = CGFloat(appPreferences.pdfRenderScale.rawValue)
        let rotationAngle = preserveRotation ?  imageView.rotationAngle : 0.0
        pdf.currentPage = page
        var tempImage = NSImage()
        tempImage.addRepresentation(pdf)
        tempImage = scaleImage(tempImage, byFactor: scale)
        guard let image = nsImageToCGImage(tempImage) else { return }
        imageView.setImage(image, imageProperties: nil)
        imageView.rotationAngle = appPreferences.resetImageRotationBetweenPages ? 0 : rotationAngle
        zoomImageViewToLogicalActualSize()

        if appPreferences.resetImageZoomBetweenPages {
            scrollView.magnification = 1.0
        }
        if appPreferences.clearCalipersBetweenPages {
            calipersView.deleteAllCalipers()
        }
        if appPreferences.recalibrateWhenChangingPages {
            clearCalibration()
        }
        calipersView.updateCalibration()
    }

    private func zoomImageViewToLogicalActualSize() {
        imageView.zoomImageToActualSize(self)

        if imageIsPDF {
            let scale = CGFloat(appPreferences.pdfRenderScale.rawValue)
            imageView.zoomFactor = imageView.zoomFactor / scale
        }
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
        zoomImageViewToLogicalActualSize()
//            imageView.zoomImageToActualSize(self)
        // since rotation can adjust zoom factor, must clear calibration
        clearCalibration()
    }

// MARK: Caliper functions
    
    func addCaliperWithDirection(_ direction: CaliperDirection) {
        let caliper = Caliper()
        // initiallize with Preferences here
        caliper.lineWidth = CGFloat(appPreferences.lineWidth)
        caliper.rounding = appPreferences.rounding
        caliper.allowNegativeValues = appPreferences.allowNegativeCaliperValues
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
        calipersView.setInitialPosition(caliper)
        calipersView.calipers.append(caliper)
        calipersView.updateCalibration()
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
        caliper.allowNegativeValues = appPreferences.allowNegativeCaliperValues
        caliper.direction = .horizontal
        caliper.autoPositionText = appPreferences.autoPositionText
        caliper.textPosition = appPreferences.timeCaliperTextPosition
        caliper.calibration = calipersView.horizontalCalibration
        caliper.verticalCalibration = calipersView.verticalCalibration
        caliper.unselectedColor = appPreferences.caliperColor
        caliper.selectedColor = appPreferences.highlightColor
        caliper.color = caliper.unselectedColor
        calipersView.setInitialPosition(caliper)
        calipersView.calipers.append(caliper)
        calipersView.updateCalibration()
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

    @IBAction func deleteAllNotes(_ sender: AnyObject) {
        calipersView.deleteAllNotes()
    }
    
    func calibrateWithPossiblePrompts() {
        if appPreferences.showPrompts {
            if inCalibration {
                // user pressed Calibrate, it's OK, do what s/he wants
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
                // Only angle calipers don't require calibration - so far.
                showAngleCaliperNoCalibrationAlert()
                return
            }

            let example = c.direction == .vertical ? "1 mV" : "1000 msec"
            let message = String(format:NSLocalizedString("Enter calibration measurement (e.g. %@)", comment:""), example)

            if calipersView.horizontalCalibration.calibrationString.isEmpty {
                calipersView.horizontalCalibration.calibrationString = appPreferences.defaultHorizontalCalibration
            }
            if calipersView.verticalCalibration.calibrationString.isEmpty {
                calipersView.verticalCalibration.calibrationString = appPreferences.defaultVerticalCalibration
            }

            let direction = c.direction
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Calibrate caliper", comment:"")
            alert.informativeText = message
            alert.alertStyle = NSAlert.Style.informational
            alert.addButton(withTitle: NSLocalizedString("Calibrate", comment:""))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment:""))

            var lastCustomCalibrationString = direction == .horizontal ? appPreferences.lastCustomHorizontalCalibration : appPreferences.lastCustomVerticalCalibration
            if lastCustomCalibrationString.isEmpty {
                lastCustomCalibrationString = direction == .horizontal ? appPreferences.defaultHorizontalCalibration : appPreferences.defaultVerticalCalibration
            }

            let accessory = makeCalibrationAccessory(
                direction: direction,
                lastCustomCalibrationString: lastCustomCalibrationString,
                defaultButtonChoice: direction == .horizontal ? appPreferences.lastHorizontalCalibrationDialogChoice : appPreferences.lastVerticalCalibrationDialogChoice
            )
            alert.accessoryView = accessory.view

            let result = alert.runModal()
            if result == NSApplication.ModalResponse.alertFirstButtonReturn {
                let inputText = accessory.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                let buttonChosen = accessory.buttonChosen
                if direction == .horizontal {
                    appPreferences.lastHorizontalCalibrationDialogChoice = buttonChosen
                    if buttonChosen == 0 {
                        appPreferences.lastCustomHorizontalCalibration = inputText
                    }
                }
                else {
                    appPreferences.lastVerticalCalibrationDialogChoice = buttonChosen
                    if buttonChosen == 0 {
                        appPreferences.lastCustomVerticalCalibration = inputText
                    }
                }
                appPreferences.save()
                if !inputText.isEmpty {
                    calibrateWithText(inputText)
                    exitCalibration()
                }
            }
        }
    }

    private func makeCalibrationAccessory(
        direction: CaliperDirection,
        lastCustomCalibrationString: String,
        defaultButtonChoice: Int = 0
    ) -> CalibrationAccessory {
        let customRadioButton = NSButton(radioButtonWithTitle: NSLocalizedString("Custom", comment:""), target: nil, action: nil)
        customRadioButton.target = self
        customRadioButton.action = #selector(calibrationRadioButtonSelected(_:))
        customRadioButton.state = .on

        var customCalibrationString = lastCustomCalibrationString
        if customCalibrationString.isEmpty {
            customCalibrationString = direction == .horizontal ? appPreferences.defaultHorizontalCalibration : appPreferences.defaultVerticalCalibration
        }

        let customTextField = NSTextField(string: customCalibrationString)
        customTextField.alignment = .right
        customTextField.target = self
        customTextField.action = #selector(calibrationCustomTextFieldSelected(_:))
        customTextField.translatesAutoresizingMaskIntoConstraints = false
        customTextField.widthAnchor.constraint(equalToConstant: 198).isActive = true

        let customRow = NSStackView(views: [customRadioButton, customTextField])
        customRow.orientation = .vertical
        customRow.alignment = .leading
        customRow.spacing = 4
        customTextField.leadingAnchor.constraint(equalTo: customRow.leadingAnchor, constant: 22).isActive = true

        let options = calibrationOptions(for: direction)
        let optionButtons = options.map { option in
            NSButton(radioButtonWithTitle: option.title, target: self, action: #selector(calibrationRadioButtonSelected(_:)))
        }
        calibrationRadioButtons = [customRadioButton] + optionButtons
        calibrationCustomTextField = customTextField
        selectRadioButton(buttons: calibrationRadioButtons, index: defaultButtonChoice)
        updateCalibrationCustomTextFieldEnabled()

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(customRow)
        optionButtons.forEach { stackView.addArrangedSubview($0) }

        let accessoryWidth: CGFloat = 220
        let accessoryHeight: CGFloat = direction == .horizontal ? 148 : 106
        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: accessoryWidth, height: accessoryHeight))
        accessoryView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: accessoryView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: accessoryView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: accessoryView.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: accessoryView.bottomAnchor)
        ])

        return CalibrationAccessory(
            view: accessoryView,
            customTextField: customTextField,
            customRadioButton: customRadioButton,
            optionButtons: optionButtons,
            options: options
        )
    }

    private func updateCalibrationCustomTextFieldEnabled() {
        calibrationCustomTextField?.isEnabled = calibrationRadioButtons.first?.state == .on
    }

    private func selectRadioButton(buttons: [NSButton], index: Int) {
        guard index >= 0 && index < buttons.count else {
            return
        }
        for button in buttons {
            button.state = .off
        }
        buttons[index].state = .on
        updateCalibrationCustomTextFieldEnabled()
    }

    @objc private func calibrationRadioButtonSelected(_ sender: NSButton) {
        calibrationRadioButtons.forEach { $0.state = $0 === sender ? .on : .off }
        updateCalibrationCustomTextFieldEnabled()
    }

    @objc private func calibrationCustomTextFieldSelected(_ sender: NSTextField) {
        calibrationRadioButtons.first?.state = .on
        calibrationRadioButtons.dropFirst().forEach { $0.state = .off }
        updateCalibrationCustomTextFieldEnabled()
    }

    private func calibrationOptions(for direction: CaliperDirection) -> [CalibrationOption] {
        if direction == .horizontal {
            return [
                CalibrationOption(title: NSLocalizedString("1000 msec", comment:""), value: "1000 msec"),
                CalibrationOption(title: NSLocalizedString("200 msec", comment:""), value: "200 msec"),
                CalibrationOption(title: NSLocalizedString("1.0 sec", comment:""), value: "1.0 sec"),
                CalibrationOption(title: NSLocalizedString("0.2 sec", comment: ""), value: "0.2 sec")
            ]
        }

        return [
            CalibrationOption(title: NSLocalizedString("1 mV", comment:""), value: "1 mV"),
            CalibrationOption(title: NSLocalizedString("10 mm", comment:""), value: "10 mm")
        ]
    }

    func calibrateWithText(_ inputText: String) {
        // caller must guarantee this
        assert(!inputText.isEmpty)
        var trimmedUnits: String = ""
        let scanner: Scanner = Scanner.localizedScanner(with: inputText) as! Scanner
        if var value = scanner.scanDouble() {
            trimmedUnits = scanner.string[scanner.currentIndex...].trimmingCharacters(in: CharacterSet.whitespaces)
            value = abs(value)
            if value > 0 {
                guard let c = calipersView.activeCaliper(), calipersView.nonZeroPoints(c) else { return }

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
                calibration.magnificationAtCalibration = Double(scrollView.magnification)
                calibration.calibrationFactorAtCalibration = value / calipersView.points(for: c)
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
                let intervalResult = abs(calipersView.getIntervalResult(c))
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
                let intervalResult = calipersView.getIntervalResult(c)
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
            let qt = abs(c.intervalInSecs(calipersView.getIntervalResult(c)))
            let meanRR = abs(rrIntervalForQTc)
            
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

    func controlTextDidChange(_ obj: Notification) {
        if obj.name.rawValue == "NSControlTextDidChangeNotification" {
            if obj.object as AnyObject? === numberTextField {
                numberStepper.integerValue = numberTextField.integerValue
            }
            if obj.object as AnyObject? === qtcNumberTextField {
                qtcNumberStepper.integerValue = qtcNumberTextField.integerValue
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
