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
    override var windowNibName: String? {
        return "MainWindowController"
    }
    
    override func awakeFromNib() {
        let path = NSBundle.mainBundle().pathForResource("Normal 12_Lead ECG", ofType: "jpg")
        let url = NSURL.fileURLWithPath(path!)
        
        imageView.setImageWithURL(url)
        imageView.doubleClickOpensImageEditPanel = true
        imageView.currentToolMode = IKToolModeMove
        imageView.zoomImageToFit(self)
    }
    
    @IBAction func openImage (sender: AnyObject) {
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
                    self.imageView.setImageWithURL(openPanel.URL)
                }
            }
        )
        
    }
    
}
