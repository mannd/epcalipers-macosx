//
//  Preferences.swift
//  EP Calipers
//
//  Created by David Mann on 1/21/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa

// from http://stackoverflow.com/questions/1275662/saving-uicolor-to-and-loading-from-nsuserdefaults
extension NSUserDefaults {
    func colorForKey(key: String) -> NSColor? {
        var color: NSColor?
        if let colorData = dataForKey(key) {
            color = NSKeyedUnarchiver.unarchiveObjectWithData(colorData) as? NSColor
        }
        return color
    }
    
    func setColor(color: NSColor?, forKey key: String) {
        var colorData: NSData?
        if let color = color {
            colorData = NSKeyedArchiver.archivedDataWithRootObject(color)
        }
        setObject(colorData, forKey: key)
    }
}

/* TODO: Preferences
Prefences will appear as a modal dialog, invoked by showPreferences action in MainWindowController.  Default preferences will be registered in AppDelegate.swift in windowDidLoad.  An accessory view for the dialog will hold the specific preference controls.
*/
class Preferences: NSObject {
    var caliperColor: NSColor? = NSColor.blueColor()
    var highlightColor: NSColor? = NSColor.redColor()
    var lineWidth: Int = 2
    var defaultCalibration: String? = "1000 msec"
    var defaultVerticalCalibration: String? = "10 mm"
    var defaultNumberOfMeanRRIntervals: Int = 3
    var defaultNumberOfQTcMeanRRIntervals: Int = 1
    var showPrompts: Bool = true    

    
    func loadPreferences() {
        let preferences = NSUserDefaults.standardUserDefaults()
        caliperColor = preferences.colorForKey("caliperColorKey")
        highlightColor = preferences.colorForKey("highlightColorKey")
        lineWidth = preferences.integerForKey("lineWidthKey")
        defaultCalibration = preferences.stringForKey("defaultCalibrationKey")
        defaultVerticalCalibration = preferences.stringForKey("defaultVerticalCalibrationKey")
        defaultNumberOfMeanRRIntervals = preferences.integerForKey("defaultNumberOfMeanRRIntervalsKey")
        defaultNumberOfQTcMeanRRIntervals = preferences.integerForKey("defaultNumberOfQTcMeanRRIntervalsKey")
        showPrompts = preferences.boolForKey("showPromptsKey")
    }
    
    func savePreferences() {
        let preferences = NSUserDefaults.standardUserDefaults()
        preferences.setColor(caliperColor, forKey: "caliperColorKey")
        preferences.setColor(highlightColor, forKey: "highlightColorKey")
        preferences.setInteger(lineWidth, forKey: "lineWidthKey")
        preferences.setObject(defaultCalibration, forKey: "defaultCalibrationKey")
        preferences.setObject(defaultVerticalCalibration, forKey: "defaultVerticalCalibrationKey")
        preferences.setInteger(defaultNumberOfMeanRRIntervals, forKey: "defaultNumberOfMeanRRIntervalsKey")
        preferences.setInteger(defaultNumberOfQTcMeanRRIntervals, forKey: "defaultNumberOfQTcMeanRRIntervalsKey")
        preferences.setBool(showPrompts, forKey: "showPromptsKey")
    }

}
