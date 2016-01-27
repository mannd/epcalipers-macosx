//
//  AppDelegate.swift
//  EP Calipers
//
//  Created by David Mann on 12/25/15.
//  Copyright © 2015 EP Studios. All rights reserved.
//

import Cocoa
import Quartz

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindowController: MainWindowController?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        let mainWindowController = MainWindowController()
        mainWindowController.showWindow(self)
        self.mainWindowController = mainWindowController
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    // ensures closed window reopened by clicking on dock
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindowController!.showWindow(self)
        return true
    }
    
    func application(sender: NSApplication, openFile filename: String) -> Bool {
        NSLog("open recent file")
        let url = NSURL.fileURLWithPath(filename)
        return mainWindowController!.openImageUrl(url, addToRecentDocuments: false)
     }

}

