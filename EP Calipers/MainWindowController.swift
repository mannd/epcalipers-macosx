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
        
        imageURL = url
        imageView.setImageWithURL(url)
        imageView.doubleClickOpensImageEditPanel = true
        imageView.currentToolMode = IKToolModeMove
        imageView.zoomImageToFit(self)
    }
    
    @IBAction func openImage(sender: AnyObject) {
        /* Present open panel. */
        let extensions = "jpg/jpeg/JPG/JPEG/png/PNG/tiff/tif/TIFF/TIF"
        let types = extensions.componentsSeparatedByString("/")
        
        /* Let the user choose an output file, then start the process of writing samples. */
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
    
    @IBAction func saveImage(sender: AnyObject) {
        let savePanel = NSSavePanel()
        
        saveOptions = IKSaveOptions(imageProperties: imageProperties as [NSObject : AnyObject], imageUTType: imageUTType)
        
        let view: NSView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
//        view.autoresizingMask = CAAutoresizingMask.LayerWidthSizable | CAAutoresizingMask.LayerHeightSizable
//        
        savePanel.accessoryView = view
        saveOptions.addSaveOptionsToView(view)
        
        
      //  saveOptions.addSaveOptionsAccessoryViewToSavePanel(savePanel)
//        // FIXME: http://stackoverflow.com/questions/27374355/nssavepanel-crashes-on-yosemite suggests
//        // this to avoid crash of NSSavePanel, but it doesn't work
//        
//        savePanel.accessoryView!.translatesAutoresizingMaskIntoConstraints = false
//        
//
//        
        savePanel.nameFieldStringValue = imageURL!.lastPathComponent!
        savePanel.beginSheetModalForWindow(self.window!, completionHandler: {
            (result: NSInteger) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.savePanelDidEnd(savePanel, returnCode: result)
            }
        })
    }
   
   
    func savePanelDidEnd (sheet: NSSavePanel, returnCode: NSInteger) {
        if returnCode == NSModalResponseOK {
            let newUTType: String = saveOptions.imageUTType
            let image: CGImage = imageView.image().takeUnretainedValue()
            if CGImageGetWidth(image) > 0 && CGImageGetHeight(image) > 0 {
                let url = sheet.URL
                let dest: CGImageDestination = CGImageDestinationCreateWithURL(url!, newUTType, 1, nil)!
                CGImageDestinationAddImage(dest, image, saveOptions.imageProperties)
                CGImageDestinationFinalize(dest)
            }
            else {
                print("*** saveImageToPath - no image")
            }
        }
    }
   
    
    // not sure we want image to zoom with window resize
//    func windowDidResize (notification: NSNotification?) {
//        imageView.zoomImageToFit(self)
//    }
    
    
}
