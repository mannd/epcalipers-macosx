//
//  SettingsView.swift
//  EP Calipers
//
//  Created by David Mann on 5/22/26.
//  Copyright © 2026 EP Studios. All rights reserved.
//

import SwiftUI

struct SettingsDraft {
    // General tab
    var transparency: Bool
    var showSampleECG: Bool
    var showPrompts: Bool
    // Calipers tab
    // Appearance heading
    var unselectedColor: Color
    var selectedColor: Color
    var lineWidth: Int
    var adjustBarThicknessForZoom: Bool
    // Measurement heading
    var rounding: Rounding
    var qtcFormula: QTcFormulaPreference
    var numberOfQTcMeanRRIntervals: Int
    var numberOfMeanRRIntervals: Int
    var allowNegativeCaliperValues: Bool
    // Calibration heading
    // Labels heading
    var caliperTextFontSize: Int
    var autoPositionText: Bool
    var adjustLabelSizeForZoom: Bool
    var timeCaliperTextPosition: TextPosition
    var amplitudeCaliperTextPosition: TextPosition

    init(_ preferences: Preferences) {
        transparency = preferences.transparency
        showSampleECG = preferences.showSampleECG
        showPrompts = preferences.showPrompts
        qtcFormula = preferences.qtcFormula
        numberOfQTcMeanRRIntervals = preferences.defaultNumberOfQTcMeanRRIntervals
        numberOfMeanRRIntervals = preferences.defaultNumberOfMeanRRIntervals
        unselectedColor = Color(preferences.caliperColor)
        selectedColor = Color(preferences.highlightColor)
        lineWidth = preferences.lineWidth
        caliperTextFontSize = preferences.caliperTextFontSize
        adjustBarThicknessForZoom = preferences.adjustBarThicknessForZoom
        adjustLabelSizeForZoom = preferences.adjustLabelSizeForZoom
        allowNegativeCaliperValues = preferences.allowNegativeCaliperValues
        rounding = preferences.rounding
        autoPositionText = preferences.autoPositionText
        timeCaliperTextPosition = preferences.timeCaliperTextPosition
        amplitudeCaliperTextPosition = preferences.amplitudeCaliperTextPosition
        // TODO: add all preferences
    }

    func apply(to preferences: Preferences) {
        preferences.transparency = transparency
        preferences.showSampleECG = showSampleECG
        preferences.qtcFormula = qtcFormula
        preferences.defaultNumberOfQTcMeanRRIntervals = numberOfQTcMeanRRIntervals
        preferences.defaultNumberOfMeanRRIntervals = numberOfMeanRRIntervals
        preferences.caliperColor = NSColor(unselectedColor)
        preferences.highlightColor = NSColor(selectedColor)
        preferences.lineWidth = lineWidth
        preferences.caliperTextFontSize = caliperTextFontSize
        preferences.adjustBarThicknessForZoom = adjustBarThicknessForZoom
        preferences.adjustLabelSizeForZoom = adjustLabelSizeForZoom
        preferences.allowNegativeCaliperValues = allowNegativeCaliperValues
        preferences.rounding = rounding
        preferences.autoPositionText = autoPositionText
        preferences.timeCaliperTextPosition = timeCaliperTextPosition
        preferences.amplitudeCaliperTextPosition = amplitudeCaliperTextPosition
    }


}

struct SettingsView: View {
    @Binding var settingsDraft: SettingsDraft
    
    var body: some View {
        TabView {
            GeneralSettingsView(settingsDraft: $settingsDraft)
                .tabItem {
                    Label {
                        Text("General", tableName: "Settings")
                    } icon: {
                        Image(systemName: "gear")
                    }
                }
            CaliperSettingsView(settingsDraft: $settingsDraft)
                .tabItem {
                    Label {
                        Text("Calipers", tableName: "Settings")
                    } icon: {
                        Image("custom-time-caliper")
                    }
                }
            NoteSettingsView()
                .tabItem {
                    Label {
                        Text("Notes", tableName: "Settings")
                    } icon: {
                        Image(systemName: "pencil.and.list.clipboard")
                    }
                }
            PdfSettingsView()
                .tabItem {
                    Label {
                        Text("PDF", tableName: "Settings")
                    } icon: {
                        Image(systemName: "text.document")
                    }
                }
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var settingsDraft: SettingsDraft

    var body: some View {
        Form {
            Toggle(isOn: $settingsDraft.transparency) {
                Text("Transparent mode at start-up", tableName: "Settings")
            }
            Toggle(isOn: $settingsDraft.showSampleECG) {
                Text("Show sample ECG at start-up", tableName: "Settings")
            }
            Toggle(isOn: $settingsDraft.showPrompts) {
                Text("Show prompts", tableName: "Settings")
            }
        }
    }
}

struct CaliperSettingsView: View {
    @Binding var settingsDraft: SettingsDraft

    var body: some View {
        Form {
            Section {
                ColorPicker(selection: $settingsDraft.unselectedColor) {
                    Text("Unselected caliper color", tableName: "Settings")
                }
                ColorPicker(selection: $settingsDraft.selectedColor) {
                    Text("Selected caliper color", tableName: "Settings")
                }
                Slider(
                    value: Binding(
                        get: { Double(settingsDraft.lineWidth) },
                        set: { settingsDraft.lineWidth = Int($0.rounded()) }
                    ),
                    in: 1...10,
                    step: 1
                ) {
                    Text("Caliper line width", tableName: "Settings")
                }
                Toggle(isOn: $settingsDraft.adjustBarThicknessForZoom) {
                    Text("Adjust bar thickness for zoom", tableName: "Settings")
                }
            } header: {
                Text("Appearance", tableName: "Settings")
                    .font(Font.headline.bold())
            }
            Section {
                Picker(selection: $settingsDraft.rounding) {
                    ForEach(Rounding.allCases, id: \.self) {
                        value in Text(value.localizedTitle).tag(value)
                    }
                } label: {
                    Text("Round msec and rate", tableName: "Settings")
                }
                Picker(selection: $settingsDraft.qtcFormula) {
                    ForEach(QTcFormulaPreference.allCases, id: \.self) { formula in
                        Text(formula.localizedTitle)
                            .tag(formula)
                    }
                } label: {
                    Text("QTc formula", tableName: "Settings")
                }
                Picker(selection: $settingsDraft.numberOfQTcMeanRRIntervals) {
                    ForEach(1...10, id: \.self) {
                        Text("\($0)")
                            .tag($0)
                    }
                } label: {
                    Text("Number of mean RR intervals for QTc", tableName: "Settings")
                }
                Picker(selection: $settingsDraft.numberOfMeanRRIntervals) {
                    ForEach(1...10, id: \.self) {
                        Text("\($0)")
                            .tag($0)
                    }
                } label: {
                    Text("Number of mean RR intervals", tableName: "Settings")
                }
                Toggle(isOn: $settingsDraft.allowNegativeCaliperValues) {
                    Text("Allow negative caliper values", tableName: "Settings")
                }

            } header: {
                Text("Measurement", tableName: "Settings")
                    .font(Font.headline.bold())
            }
            Section {

            } header: {
                Text("Calibration", tableName: "Settings")
                    .font(Font.headline.bold())
            }
            Section {
                Picker(selection: $settingsDraft.caliperTextFontSize) {
                    ForEach(10...36, id: \.self) {
                        Text("\($0)")
                            .tag($0)
                    }
                } label: {
                    Text("Caliper label font size", tableName: "Settings")
                }
                Toggle(isOn: $settingsDraft.autoPositionText) {
                    Text("Auto-position Text", tableName: "Settings")
                }
                Toggle(isOn: $settingsDraft.adjustLabelSizeForZoom) {
                    Text("Adjust label size for zoom", tableName: "Settings")
                }
                Picker(selection: $settingsDraft.timeCaliperTextPosition) {
                    Text("Center above").tag(TextPosition.centerAbove)
                    Text("Center below").tag (TextPosition.centerBelow)
                    Text("Left").tag(TextPosition.left)
                    Text("Right").tag(TextPosition.right)
                } label: {
                    Text("Time caliper label position", tableName: "Settings")
                }
                Picker(selection: $settingsDraft.amplitudeCaliperTextPosition) {
                    Text("Left").tag(TextPosition.left)
                    Text("Right").tag(TextPosition.right)
                    Text("Top").tag(TextPosition.top)
                    Text("Bottom").tag(TextPosition.bottom)
                } label: {
                    Text("Amplitude caliper label position", tableName: "Settings")
                }
            } header: {
                Text("Labels", tableName: "Settings")
                    .font(Font.headline.bold())
            }
            Section {

            } header: {
                Text("Marching Calipers", tableName: "Settings")
                    .font(Font.headline.bold())
            }
        }
    }
}

struct NoteSettingsView: View {
    var body: some View {
        Form {
            Text("Hello, World!")
        }
    }
}

struct PdfSettingsView: View {
    var body: some View {
        Form {
            Text("Hello, World!")
        }
    }
}

#Preview {
    SettingsView(settingsDraft: .constant(SettingsDraft(Preferences.shared)))
        .padding(20)
        .frame(width: 560, height: 600)
}
