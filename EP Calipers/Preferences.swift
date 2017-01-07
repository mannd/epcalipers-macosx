//
//  Preferences.swift
//  EP Calipers
//
//  Created by David Mann on 1/21/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import Cocoa

// from http://stackoverflow.com/questions/1275662/saving-uicolor-to-and-loading-from-nsuserdefaults
extension UserDefaults {
    func colorForKey(_ key: String) -> NSColor? {
        var color: NSColor?
        if let colorData = data(forKey: key) {
            color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? NSColor
        }
        return color
    }
    
    func setColor(_ color: NSColor?, forKey key: String) {
        var colorData: Data?
        if let color = color {
            colorData = NSKeyedArchiver.archivedData(withRootObject: color)
        }
        set(colorData, forKey: key)
    }
}

class Preferences: NSObject {
    var caliperColor: NSColor? = NSColor.blue
    var highlightColor: NSColor? = NSColor.red
    var lineWidth: Int = 2
    var defaultCalibration: String? = "1000 msec"
    var defaultVerticalCalibration: String? = "10 mm"
    var defaultNumberOfMeanRRIntervals: Int = 3
    var defaultNumberOfQTcMeanRRIntervals: Int = 1
    var showPrompts: Bool = true
    var roundMsecRate: Bool = true

    
    func loadPreferences() {
        let preferences = UserDefaults.standard
        caliperColor = preferences.colorForKey("caliperColorKey")
        highlightColor = preferences.colorForKey("highlightColorKey")
        lineWidth = preferences.integer(forKey: "lineWidthKey")
        defaultCalibration = preferences.string(forKey: "defaultCalibrationKey")
        defaultVerticalCalibration = preferences.string(forKey: "defaultVerticalCalibrationKey")
        defaultNumberOfMeanRRIntervals = preferences.integer(forKey: "defaultNumberOfMeanRRIntervalsKey")
        defaultNumberOfQTcMeanRRIntervals = preferences.integer(forKey: "defaultNumberOfQTcMeanRRIntervalsKey")
        showPrompts = preferences.bool(forKey: "showPromptsKey")
        roundMsecRate = preferences.bool(forKey: "roundMsecRateKey")
    }
    
    func savePreferences() {
        let preferences = UserDefaults.standard
        preferences.setColor(caliperColor, forKey: "caliperColorKey")
        preferences.setColor(highlightColor, forKey: "highlightColorKey")
        preferences.set(lineWidth, forKey: "lineWidthKey")
        preferences.set(defaultCalibration, forKey: "defaultCalibrationKey")
        preferences.set(defaultVerticalCalibration, forKey: "defaultVerticalCalibrationKey")
        preferences.set(defaultNumberOfMeanRRIntervals, forKey: "defaultNumberOfMeanRRIntervalsKey")
        preferences.set(defaultNumberOfQTcMeanRRIntervals, forKey: "defaultNumberOfQTcMeanRRIntervalsKey")
        preferences.set(showPrompts, forKey: "showPromptsKey")
        preferences.set(roundMsecRate, forKey: "roundMsecRateKey")
    }

}
