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
            color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData)
        }
        return color
    }
    
    func setColor(_ color: NSColor?, forKey key: String) {
        var colorData: Data?
        if let color = color {
            colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
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

class Preferences {
    static let caliperColorKey = "caliperColorKey"
    static let highlightColorKey = "highlightColorKey"
    static let lineWidthKey = "lineWidthKey"
    static let defaultHorizontalCalibrationKey = "defaultHorizontalCalibration"
    static let defaultVerticalCalibrationKey = "defaultVerticalCalibration"
    static let defaultNumberOfMeanRRIntervalsKey = "defaultNumberOfMeanRRIntervalsKey"
    static let defaultNumberOfQTcMeanRRIntervalsKey = "defaultNumberOfQTcMeanRRIntervalsKey"
    static let showPromptsKey = "showPromptsKey"
    static let roundingKey = "roundingKey"
    static let qtcFormulaKey = "qtcFormulaKey"
    static let transparencyKey = "transparencyKey"
    static let showSampleECGKey = "showSampleECGKey"
    static let autoPositionTextKey = "autoPositionTextKey"
    static let timeCaliperTextPositionKey = "timeCaliperTextPositionKey"
    static let amplitudeCaliperTextPositionKey = "amplitudeCaliperTextPositionKey"
    static let numberOfMarchingComponentsKey = "numberOfMarchingComponentsKey"
    static let deemphasizeMarchingComponentsKey = "deemphasizeMarchingComponentsKey"

    var caliperColor: NSColor = NSColor.systemBlue
    var highlightColor: NSColor = NSColor.systemRed
    var lineWidth: Int = 2
    var defaultHorizontalCalibration: String = NSLocalizedString("1000 msec", comment: "")
    var defaultVerticalCalibration: String = NSLocalizedString("10 mm", comment: "")
    var defaultNumberOfMeanRRIntervals: Int = 3
    var defaultNumberOfQTcMeanRRIntervals: Int = 1
    var showPrompts: Bool = true
    var transparency = false
    var qtcFormula: QTcFormulaPreference = .Bazett
    var rounding: Rounding = .ToInteger
    var autoPositionText: Bool = true
    var timeCaliperTextPosition: TextPosition = .centerAbove
    var amplitudeCaliperTextPosition: TextPosition = .right
    var showSampleECG: Bool = true
    var numberOfMarchingComponents = Caliper.maxMarchingComponents
    var deemphasizeMarchingComponents: Bool = true

    func registerDefaults() {
        // Color defaults are handled in loadPreferences().
        let defaults = [
            Self.lineWidthKey: lineWidth,
            Self.defaultHorizontalCalibrationKey: defaultHorizontalCalibration,
            Self.defaultVerticalCalibrationKey: defaultVerticalCalibration,
            Self.defaultNumberOfMeanRRIntervalsKey: defaultNumberOfMeanRRIntervals,
            Self.defaultNumberOfQTcMeanRRIntervalsKey: defaultNumberOfQTcMeanRRIntervals,
            Self.showPromptsKey: showPrompts,
            Self.roundingKey: Rounding.ToInteger.rawValue,
            Self.qtcFormulaKey: QTcFormulaPreference.Bazett.rawValue,
            Self.transparencyKey: false,
            Self.showSampleECGKey: true,
            Self.autoPositionTextKey: true,
            Self.timeCaliperTextPositionKey: timeCaliperTextPosition.rawValue,
            Self.amplitudeCaliperTextPositionKey: TextPosition.right.rawValue,
            Self.numberOfMarchingComponentsKey: numberOfMarchingComponents,
            Self.deemphasizeMarchingComponentsKey: deemphasizeMarchingComponents,
        ] as [String : Any]
        let userDefaults = UserDefaults.standard
        userDefaults.register(defaults: defaults)
    }

    func loadPreferences() {
        let preferences = UserDefaults.standard
        caliperColor = preferences.colorForKey(Self.caliperColorKey) ?? caliperColor
        highlightColor = preferences.colorForKey(Self.highlightColorKey) ?? highlightColor
        lineWidth = preferences.integer(forKey: Self.lineWidthKey)
        defaultHorizontalCalibration = preferences.string(forKey: Self.defaultHorizontalCalibrationKey) ?? defaultHorizontalCalibration
        defaultVerticalCalibration = preferences.string(forKey: Self.defaultVerticalCalibrationKey) ?? defaultVerticalCalibration
        defaultNumberOfMeanRRIntervals = preferences.integer(forKey: Self.defaultNumberOfMeanRRIntervalsKey)
        defaultNumberOfQTcMeanRRIntervals = preferences.integer(forKey: Self.defaultNumberOfQTcMeanRRIntervalsKey)
        showPrompts = preferences.bool(forKey: Self.showPromptsKey)
        transparency = preferences.bool(forKey: Self.transparencyKey)
        showSampleECG = preferences.bool(forKey: Self.showSampleECGKey)
        qtcFormula = QTcFormulaPreference(rawValue: preferences.integer(forKey: Self.qtcFormulaKey)) ?? .Bazett
        rounding = Rounding(rawValue: preferences.integer(forKey: Self.roundingKey)) ?? .ToInteger
        autoPositionText = preferences.bool(forKey: Self.autoPositionTextKey)
        timeCaliperTextPosition = TextPosition(rawValue: preferences.integer(forKey: Self.timeCaliperTextPositionKey)) ?? .centerAbove
        amplitudeCaliperTextPosition = TextPosition(rawValue: preferences.integer(forKey: Self.amplitudeCaliperTextPositionKey)) ?? .right
        numberOfMarchingComponents = preferences.integer(forKey: Self.numberOfMarchingComponentsKey)
        deemphasizeMarchingComponents = preferences.bool(forKey: Self.deemphasizeMarchingComponentsKey)
    }
    
    func savePreferences() {
        let preferences = UserDefaults.standard
        preferences.setColor(caliperColor, forKey: Self.caliperColorKey)
        preferences.setColor(highlightColor, forKey: Self.highlightColorKey)
        preferences.set(lineWidth, forKey: Self.lineWidthKey)
        preferences.set(defaultHorizontalCalibration, forKey: Self.defaultHorizontalCalibrationKey)
        preferences.set(defaultVerticalCalibration, forKey: Self.defaultVerticalCalibrationKey)
        preferences.set(defaultNumberOfMeanRRIntervals, forKey: Self.defaultNumberOfMeanRRIntervalsKey)
        preferences.set(defaultNumberOfQTcMeanRRIntervals, forKey: Self.defaultNumberOfQTcMeanRRIntervalsKey)
        preferences.set(showPrompts, forKey: Self.showPromptsKey)
        preferences.set(transparency, forKey: Self.transparencyKey)
        preferences.set(showSampleECG, forKey: Self.showSampleECGKey)
        preferences.set(qtcFormula.rawValue, forKey: Self.qtcFormulaKey)
        preferences.set(rounding.rawValue, forKey: Self.roundingKey)
        preferences.set(autoPositionText, forKey: Self.autoPositionTextKey)
        preferences.set(timeCaliperTextPosition.rawValue, forKey: Self.timeCaliperTextPositionKey)
        preferences.set(amplitudeCaliperTextPosition.rawValue, forKey: Self.amplitudeCaliperTextPositionKey)
        preferences.set(numberOfMarchingComponents, forKey: Self.numberOfMarchingComponentsKey)
        preferences.set(deemphasizeMarchingComponents, forKey: Self.deemphasizeMarchingComponentsKey)
    }
}
