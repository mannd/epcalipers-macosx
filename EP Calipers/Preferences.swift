//
//  Preferences.swift
//  EP Calipers
//
//  Created by David Mann on 1/21/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa

/* TODO: Preferences
Prefences will appear as a modal dialog, invoked by showPreferences action in MainWindowController.  Default preferences will be registered in AppDelegate.swift in windowDidLoad.  An accessory view for the dialog will hold the specific preference controls.
*/
class Preferences: NSObject {
    var caliperColor: NSColor = NSColor.blueColor()
    var highlightColor: NSColor = NSColor.redColor()
    var lineWidth: Int = 2
    var defaultCalibration: String = "1000 msec"
    var defaultVerticalCalibration = "10 mm"
    var defaultNumberOfMeanRRIntervals: Int = 3
    var defaultNumberOfQTcMeanRRIntervals: Int = 1
    var showPrompts: Bool = true
    // any others?

    
    func loadPreferences() {
        // store color values of RGB numbers?  Preference interface doesn't directly support NSColor
    }
}
