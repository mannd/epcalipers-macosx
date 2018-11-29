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

public enum QTcFormulaPreference: Int {
    case Bazett = 0
    case Framingham = 1
    case Hodges = 2
    case Fridericia = 3
    case all = 4
}

public enum Rounding: Int {
    case ToInteger = 0 // 123 msec
    case ToFourPlaces = 1 // 12.34 msec 123.4 msec
    case ToTenths = 2 // 123.4 msec 12.3 msec
    case ToHundredths = 3 // 123.45 msec 12.34 msec
    case None = 4 // for debugging only 123.456789 msec
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
    var transparency = false
    var qtcFormula: QTcFormulaPreference = .Bazett
    var rounding: Rounding = .ToInteger
    var autoPositionText: Bool = true
    var timeCaliperTextPosition: TextPosition = .centerAbove
    var amplitudeCaliperTextPosition: TextPosition = .right

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
        transparency = preferences.bool(forKey: "transparency")
        if let formula = QTcFormulaPreference(rawValue: preferences.integer(forKey: "qtcFormula")) {
            qtcFormula = formula
        }
        else {
            qtcFormula = .Bazett
        }
        if let roundPreference = Rounding(rawValue: preferences.integer(forKey: "rounding")) {
            rounding = roundPreference
        }
        else {
            rounding = .ToInteger
        }
        autoPositionText = preferences.bool(forKey: "autoPositionText")
        timeCaliperTextPosition = TextPosition(rawValue: preferences.integer(forKey: "timeCaliperTextPosition")) ?? .centerAbove
        amplitudeCaliperTextPosition = TextPosition(rawValue: preferences.integer(forKey: "amplitudeCaliperTextPosition")) ?? .right
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
        preferences.set(transparency, forKey: "transparency")
        preferences.set(qtcFormula.rawValue, forKey: "qtcFormula")
        preferences.set(rounding.rawValue, forKey: "rounding")
        preferences.set(autoPositionText, forKey: "autoPositionText")
        preferences.set(timeCaliperTextPosition.rawValue, forKey: "timeCaliperTextPosition")
        preferences.set(amplitudeCaliperTextPosition.rawValue, forKey: "amplitudeCaliperTextPosition")
    }
}
