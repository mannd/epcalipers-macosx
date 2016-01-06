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
//    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var calipersView: CalipersView!
    
    var imageProperties: NSDictionary = Dictionary<String, String>()
    var imageUTType: String = ""
    var saveOptions: IKSaveOptions = IKSaveOptions()
    var imageURL: NSURL? = nil

    
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
        
        
    
// FIXME: needs more than below to drag and drop
//scrollView.addSubview(calipersView)
// FIXME: need to selectively pass mouse events through
        calipersView.hidden = true
      //  super.awakeFromNib()
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
//            imageView.setImage(image, imageProperties: imageProperties as [NSObject : AnyObject])
//            imageView.zoomImageToFit(self)
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
