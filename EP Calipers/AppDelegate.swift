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

    let secondaryWindowsMaxCount = 5
    var mainWindowController: MainWindowController?
    var secondaryWindows: [MainWindowController] = [MainWindowController]()
    var externalURL: URL? = nil
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // uncomment below to clear default prefs for testing
//        let appDomain = Bundle.main.bundleIdentifier
//        UserDefaults.standard.removePersistentDomain(forName: appDomain!)
//        NSLog("WARNING, Preferences are set to be cleared with each start of app!!")

        // Insert code here to initialize your application

        // Add touchbar support
        if #available(OSX 10.12.2, *) {
            NSApplication.shared.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        } 

        let mainWindowController = MainWindowController()
        mainWindowController.showWindow(self)
        self.mainWindowController = mainWindowController
        if let url = externalURL {
            mainWindowController.openURL(url, addToRecentDocuments: false)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(removeWindowController(_:)), name: NSWindow.willCloseNotification, object: nil)
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // ensures closed window reopened by clicking on dock
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Bring app window when dock icon gets clicked
        if !flag {
            for window: AnyObject in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        // needed to implement Open Recent... menu item
        let url = URL(fileURLWithPath: filename)
        if let controller = mainWindowController {
            controller.openURL(url, addToRecentDocuments: false)
        }
        externalURL = url
        return true
     }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func newWindow(_ sender: Any) {
        if secondaryWindows.count < secondaryWindowsMaxCount {
        let secondaryController = MainWindowController()
        secondaryWindows.append(secondaryController)
        secondaryController.showWindow(self)
        } else {
            let alert = NSAlert()
            alert.alertStyle = NSAlert.Style.warning
            alert.messageText = NSLocalizedString("Maximum number of windows already open.", comment:"")
            alert.addButton(withTitle: NSLocalizedString("OK", comment:""))
            alert.runModal()
            print("too many windows")
        }
    }

    @objc func removeWindowController(_ notification: NSNotification) {
        if let window = notification.object as? NSWindow {
            secondaryWindows.removeAll { $0.window == window }
        }
    }

}

