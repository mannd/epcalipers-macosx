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
    
    var imageProperties: NSDictionary = Dictionary<String, String>()
    var imageUTType: String = ""
    var saveOptions: IKSaveOptions = IKSaveOptions()
    var imageURL: NSURL? = nil
    
    // These are taken from the Apple IKImageView demo
    let zoomInFactor: CGFloat = 1.414214
    let zoomOutFactor: CGFloat = 0.7071068

    
    override var windowNibName: String? {
        return "MainWindowController"
    }
    
    override func awakeFromNib() {
        let path = NSBundle.mainBundle().pathForResource("Normal 12_Lead ECG", ofType: "jpg")
        let url = NSURL.fileURLWithPath(path!)
        //
        //        imageURL = url
        //        let image = NSImage(fURL: url)
        
        imageView.setImageWithURL(url)
        imageView.editable = true
        imageView.currentToolMode = IKToolModeMove
        imageView.delegate = self
        // calipersView unhandled events are passed to imageView
        calipersView.nextResponder = imageView
        calipersView.imageView = imageView
        
// FIXME: a little test to try to draw the first caliper
        let caliper: Caliper = Caliper()
        caliper.setInitialPositionInRect(calipersView.bounds)
        calipersView.calipers.append(caliper)
        
        
        if NSWindowController.instancesRespondToSelector(Selector("awakeFromNib")) {
            super.awakeFromNib()
        }

    }
    
    @IBAction func doZoom(sender: AnyObject) {
        if sender.isKindOfClass(NSSegmentedControl) {
            var zoomFactor: CGFloat
            let zoom = sender.selectedSegment
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
            default: break
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
//// FIXME: Accessory view doesn't work
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
    
    
}
