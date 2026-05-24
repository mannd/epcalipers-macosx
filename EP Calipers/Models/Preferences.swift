//
//  Preferences.swift
//  EP Calipers
//
//  Created by David Mann on 1/21/16.
//  Copyright © 2016 EP Studios. All rights reserved.
//

import SwiftUI

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

enum QTcFormulaPreference: Int, CaseIterable {
    case Bazett = 0
    case Framingham = 1
    case Hodges = 2
    case Fridericia = 3
    case all = 4

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .Bazett: return "Bazett"
        case .Framingham: return "Framingham"
        case .Hodges: return "Hodges"
        case .Fridericia: return "Fridericia"
        case .all: return "All"
        }
    }
}

enum Rounding: Int, CaseIterable {
    case ToInteger = 0 // 123 msec
    case ToFourPlaces = 1 // 12.34 msec 123.4 msec
    case ToTenths = 2 // 123.4 msec 12.3 msec
    case ToHundredths = 3 // 123.45 msec 12.34 msec
    //case None = 4 // for debugging only 123.456789 msec

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .ToInteger: return "To integer"
        case .ToFourPlaces: return "To 4 digits"
        case .ToTenths: return "To tenths"
        case .ToHundredths: return "To hundredths"
        //case .None: return "None"
        }
    }
}

// Affects PDF resolution
enum PdfRenderScale: Int {
    case Low = 1
    case Medium = 2
    case High = 4
}

/// This class holds all the preferences, aka settings for the app.
///
/// The class has a private init(), so obtained the shared instance via ``Preferences.shared``.
///
/// >Important: When adding new preferences, update ``registerDefaults()``, ``load()``
/// and ``save()``.
class Preferences: ObservableObject {
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
    static let noteTextFontSizeKey = "noteTextFontSizeKey"
    static let noteTextColorKey = "noteTextColorKey"
    static let noteTextBoxWidthKey = "noteTextBoxWidthKey"
    static let noteTextBoxHeightKey = "noteTextBoxHeightKey"
    static let caliperTextFontSizeKey = "caliperTextFontSizeKey"
    static let lastHorizontalCalibrationKey = "lastHorizontalCalibrationKey"
    static let lastVerticalCalibrationKey = "lastVerticalCalibrationKey"
    static let lastCustomHorizontalCalibrationKey = "lastCustomHorizontalCalibrationKey"
    static let lastCustomVerticalCalibrationKey = "lastCustomVerticalCalibrationKey"

    // New preferences to be feature complete compared with
    // EP Calipers 3 for Windows
    static let allowNegativeCaliperValuesKey = "allowNegativeCaliperValuesKey" // default == true
    static let showBrugadaTriangleKey = "showBrugadaTriangleKey" // default == true
    // Zoom
    static let adjustBarThicknessForZoomKey = "adjustBarThicknessForZoomKey"
    static let adjustLabelSizeForZoomKey = "adjustLabelSizeForZoomKey"
    // PDF
    static let pdfRenderScaleKey = "pdfRenderScaleKey" // affects resolution of PDFs
    static let recalibrateWhenChangingPagesKey = "recalibrateWhenChangingPagesKey"
    static let resetImageZoomBetweenPagesKey = "resetImageZoomBetweenPagesKey"
    static let resetImageRotationBetweenPagesKey = "resetImageRotationBetweenPagesKey"
    static let clearCalipersBetweenPagesKey = "clearCalibrationBetweenPagesKey"

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
    var noteTextFontSize: Int = 12
    var noteTextColor: NSColor = NSColor.black
    var noteTextBoxWidth: CGFloat = 180.0
    var noteTextBoxHeight: CGFloat = 80.0
    var caliperTextFontSize: Int = 24
    // New preferences as of 5/2026
    var allowNegativeCaliperValues: Bool = true
    var adjustLabelSizeForZoom: Bool = true
    var adjustBarThicknessForZoom: Bool = true
    var showBrugadaTriangle: Bool = true

    // PDF
    // NOTE: These preferences don't affect the currently loaded PFD page,
    // just subsequent pages.
    // Defaults roughtly mimic current behavior of the app.
    var pdfRenderScale: PdfRenderScale = .High
    var recalibrateWhenChangingPages: Bool = false // clear calibration when changing pages
    var resetImageZoomBetweenPages: Bool = false
    var resetImageRotationBetweenPages: Bool = false
    var clearCalipersBetweenPages: Bool = false  // deletes all calipers when changing pages

    // Preferences hidden from the user
    var lastHorizontalCalibrationDialogChoice = 0
    var lastVerticalCalibrationDialogChoice = 0
    var lastCustomHorizontalCalibration: String = ""
    var lastCustomVerticalCalibration: String = ""

    static let shared = Preferences()
    private init() {
        registerDefaults()
    }

    func registerDefaults() {
        // Color defaults are handled in load().
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
            Self.noteTextFontSizeKey: noteTextFontSize,
            Self.noteTextColorKey: noteTextColor,
            Self.noteTextBoxWidthKey: noteTextBoxWidth,
            Self.noteTextBoxHeightKey: noteTextBoxHeight,
            Self.caliperTextFontSizeKey: caliperTextFontSize,
            Self.allowNegativeCaliperValuesKey: allowNegativeCaliperValues,
            Self.adjustLabelSizeForZoomKey: adjustLabelSizeForZoom,
            Self.adjustBarThicknessForZoomKey: adjustBarThicknessForZoom,
            Self.showBrugadaTriangleKey: showBrugadaTriangle,
            Self.pdfRenderScaleKey: pdfRenderScale.rawValue,
            Self.recalibrateWhenChangingPagesKey: recalibrateWhenChangingPages,
            Self.resetImageZoomBetweenPagesKey: resetImageZoomBetweenPages,
            Self.resetImageRotationBetweenPagesKey: resetImageRotationBetweenPages,
            Self.clearCalipersBetweenPagesKey: clearCalipersBetweenPages,
            // preferences hidden from user
            Self.lastVerticalCalibrationKey: lastVerticalCalibrationDialogChoice,
            Self.lastHorizontalCalibrationKey: lastHorizontalCalibrationDialogChoice,
            Self.lastCustomVerticalCalibrationKey: lastCustomVerticalCalibration,
            Self .lastCustomHorizontalCalibrationKey: lastCustomHorizontalCalibration,
        ] as [String : Any]
        let userDefaults = UserDefaults.standard
        userDefaults.register(defaults: defaults)
    }

    func load() {
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
        noteTextFontSize = preferences.integer(forKey: Self.noteTextFontSizeKey)
        noteTextColor = preferences.colorForKey(Self.noteTextColorKey) ?? .black
        noteTextBoxWidth = CGFloat(preferences.float(forKey: Self.noteTextBoxWidthKey))
        noteTextBoxHeight = CGFloat(preferences.float(forKey: Self.noteTextBoxHeightKey))
        caliperTextFontSize = preferences.integer(forKey: Self.caliperTextFontSizeKey)
        allowNegativeCaliperValues = preferences.bool(forKey: Self.allowNegativeCaliperValuesKey)
        adjustLabelSizeForZoom = preferences.bool(forKey: Self.adjustLabelSizeForZoomKey)
        adjustBarThicknessForZoom = preferences.bool(forKey: Self.adjustBarThicknessForZoomKey)
        showBrugadaTriangle = preferences.bool(forKey: Self.showBrugadaTriangleKey)
        pdfRenderScale = PdfRenderScale(rawValue: preferences.integer(forKey: Self.pdfRenderScaleKey)) ?? .High
        recalibrateWhenChangingPages = preferences.bool(forKey: Self.recalibrateWhenChangingPagesKey)
        resetImageZoomBetweenPages = preferences.bool(forKey: Self.resetImageZoomBetweenPagesKey)
        resetImageRotationBetweenPages = preferences.bool(forKey: Self.resetImageRotationBetweenPagesKey)
        clearCalipersBetweenPages = preferences.bool(forKey: Self.clearCalipersBetweenPagesKey)

        // preferencses hidden from user
        lastVerticalCalibrationDialogChoice = preferences.integer(forKey: Self.lastVerticalCalibrationKey)
        lastHorizontalCalibrationDialogChoice = preferences.integer(forKey: Self.lastHorizontalCalibrationKey)
        // At start of app the custom calibrations are the default calibrations.
        lastCustomVerticalCalibration = defaultVerticalCalibration
        lastCustomHorizontalCalibration = defaultHorizontalCalibration
    }

    func save() {
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
        preferences.set(noteTextFontSize, forKey: Self.noteTextFontSizeKey)
        preferences.setColor(noteTextColor, forKey: Self.noteTextColorKey)
        preferences.set(noteTextBoxWidth, forKey: Self.noteTextBoxWidthKey)
        preferences.set(noteTextBoxHeight, forKey: Self.noteTextBoxHeightKey)
        preferences.set(caliperTextFontSize, forKey: Self.caliperTextFontSizeKey)
        preferences.set(allowNegativeCaliperValues, forKey: Self.allowNegativeCaliperValuesKey)
        preferences.set(adjustLabelSizeForZoom, forKey: Self.adjustLabelSizeForZoomKey)
        preferences.set(adjustBarThicknessForZoom, forKey: Self.adjustBarThicknessForZoomKey)
        preferences.set(showBrugadaTriangle, forKey: Self.showBrugadaTriangleKey)
        preferences.set(pdfRenderScale.rawValue, forKey: Self.pdfRenderScaleKey)
        preferences.set(recalibrateWhenChangingPages, forKey: Self.recalibrateWhenChangingPagesKey)
        preferences.set(resetImageZoomBetweenPages, forKey: Self.resetImageZoomBetweenPagesKey)
        preferences.set(resetImageRotationBetweenPages, forKey: Self.resetImageRotationBetweenPagesKey)
        preferences.set(clearCalipersBetweenPages, forKey: Self.clearCalipersBetweenPagesKey)

        // preferences hidden from user
        preferences.set(lastVerticalCalibrationDialogChoice, forKey: Self.lastVerticalCalibrationKey)
        preferences.set(lastHorizontalCalibrationDialogChoice, forKey: Self.lastHorizontalCalibrationKey)
        preferences.set(lastCustomVerticalCalibration, forKey: Self.lastCustomVerticalCalibrationKey)
        preferences.set(lastCustomHorizontalCalibration, forKey: Self.lastCustomHorizontalCalibrationKey)
    }
}
