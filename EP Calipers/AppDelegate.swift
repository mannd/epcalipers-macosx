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
    var externalURL: NSURL? = nil
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // uncomment below to clear default prefs for testing
//        let appDomain = NSBundle.mainBundle().bundleIdentifier
//        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)

        // Insert code here to initialize your application
        let mainWindowController = MainWindowController()
        mainWindowController.showWindow(self)
        self.mainWindowController = mainWindowController
        if let url = externalURL {
            mainWindowController.openURL(url, addToRecentDocuments: false)
        }
        
        NSLog("applicationDidFinishLaunching")
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
        // needed to implement Open Recent... menu item
        let url = NSURL.fileURLWithPath(filename)
        if let controller = mainWindowController {
            controller.openURL(url, addToRecentDocuments: false)
        }
        externalURL = url
        return true
     }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    
}

