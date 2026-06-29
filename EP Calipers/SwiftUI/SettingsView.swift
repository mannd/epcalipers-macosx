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
    // Measurement heading
    var rounding: Rounding
    var qtcFormula: QTcFormulaPreference
    var numberOfQTcMeanRRIntervals: Int
    var numberOfMeanRRIntervals: Int
    var allowNegativeCaliperValues: Bool
    var showBrugadaTriangle: Bool
    // Calibration heading
    var timeCalibration: String
    var amplitudeCalibration: String
    // Labels heading
    var caliperTextFontSize: Int
    var autoPositionText: Bool
    var timeCaliperTextPosition: TextPosition
    var amplitudeCaliperTextPosition: TextPosition
    // Marching calipers heading
    var deemphasizeMarchingComponents: Bool
    var numberOfMarchingComponents: Int
    // Notes tab
    var noteTextFontSize: Int
    var noteTextColor: Color
    var noteTextBoxWidth: Int
    var noteTextBoxHeight: Int
    // PDF tab
    var pdfRenderScale: PdfRenderScale
    var recalibrateWhenChangingPages: Bool
    var resetImageZoomBetweenPages: Bool
    var resetImageRotationBetweenPages: Bool
    var clearCalipersBetweenPages: Bool
    var adjustSidebarLength: Bool
    var sidebarLength: Int

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
        allowNegativeCaliperValues = preferences.allowNegativeCaliperValues
        rounding = preferences.rounding
        autoPositionText = preferences.autoPositionText
        timeCaliperTextPosition = preferences.timeCaliperTextPosition
        amplitudeCaliperTextPosition = preferences.amplitudeCaliperTextPosition
        timeCalibration = preferences.defaultHorizontalCalibration
        amplitudeCalibration = preferences.defaultVerticalCalibration
        deemphasizeMarchingComponents = preferences.deemphasizeMarchingComponents
        numberOfMarchingComponents = preferences.numberOfMarchingComponents
        showBrugadaTriangle = preferences.showBrugadaTriangle
        noteTextFontSize = preferences.noteTextFontSize
        noteTextColor = Color(preferences.noteTextColor)
        noteTextBoxWidth = Int(preferences.noteTextBoxWidth)
        noteTextBoxHeight = Int(preferences.noteTextBoxHeight)
        pdfRenderScale = preferences.pdfRenderScale
        recalibrateWhenChangingPages = preferences.recalibrateWhenChangingPages
        resetImageZoomBetweenPages = preferences.resetImageZoomBetweenPages
        resetImageRotationBetweenPages = preferences.resetImageRotationBetweenPages
        clearCalipersBetweenPages = preferences.clearCalipersBetweenPages
        adjustSidebarLength = preferences.adjustSidebarLength
        sidebarLength = Int(preferences.sidebarLength)
    }

    func apply(to preferences: Preferences) {
        preferences.transparency = transparency
        preferences.showSampleECG = showSampleECG
        preferences.showPrompts = showPrompts
        preferences.qtcFormula = qtcFormula
        preferences.defaultNumberOfQTcMeanRRIntervals = numberOfQTcMeanRRIntervals
        preferences.defaultNumberOfMeanRRIntervals = numberOfMeanRRIntervals
        preferences.caliperColor = NSColor(unselectedColor)
        preferences.highlightColor = NSColor(selectedColor)
        preferences.lineWidth = lineWidth
        preferences.caliperTextFontSize = caliperTextFontSize
        preferences.allowNegativeCaliperValues = allowNegativeCaliperValues
        preferences.rounding = rounding
        preferences.autoPositionText = autoPositionText
        preferences.timeCaliperTextPosition = timeCaliperTextPosition
        preferences.amplitudeCaliperTextPosition = amplitudeCaliperTextPosition
        preferences.defaultHorizontalCalibration = timeCalibration
        preferences.defaultVerticalCalibration = amplitudeCalibration
        preferences.deemphasizeMarchingComponents = deemphasizeMarchingComponents
        preferences.numberOfMarchingComponents = numberOfMarchingComponents
        preferences.showBrugadaTriangle = showBrugadaTriangle
        preferences.noteTextFontSize = noteTextFontSize
        preferences.noteTextColor = NSColor(noteTextColor)
        preferences.noteTextBoxWidth = CGFloat(noteTextBoxWidth)
        preferences.noteTextBoxHeight = CGFloat(noteTextBoxHeight)
        preferences.pdfRenderScale = pdfRenderScale
        preferences.clearCalipersBetweenPages = clearCalipersBetweenPages
        preferences.recalibrateWhenChangingPages = recalibrateWhenChangingPages
        preferences.resetImageZoomBetweenPages = resetImageZoomBetweenPages
        preferences.resetImageRotationBetweenPages = resetImageRotationBetweenPages
        preferences.adjustSidebarLength = adjustSidebarLength
        preferences.sidebarLength = CGFloat(sidebarLength)
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
            NoteSettingsView(settingsDraft: $settingsDraft)
                .tabItem {
                    Label {
                        Text("Notes", tableName: "Settings")
                    } icon: {
                        Image(systemName: "pencil.and.list.clipboard")
                    }
                }
            PdfSettingsView(settingsDraft: $settingsDraft)
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
    @State private var sidebarLengthText = ""

    private static let sidebarLengthRange = 20...300

    private var sidebarLengthTextBinding: Binding<String> {
        Binding(
            get: { sidebarLengthText },
            set: { newValue in
                sidebarLengthText = newValue
                updateSidebarLengthDraft(from: newValue)
            }
        )
    }

    var body: some View {
        ScrollView {
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
                    }.frame(width: 350)
                    Toggle(isOn: $settingsDraft.adjustSidebarLength) {
                        Text("Adjustable side bar length", tableName: "Settings")
                    }
                    HStack {
                        Text("Side bar length", tableName: "Settings")
                        TextField("Value", text: sidebarLengthTextBinding, onEditingChanged: { isEditing in
                            if !isEditing {
                                commitSidebarLengthText()
                            }
                        }, onCommit: {
                            commitSidebarLengthText()
                        })
                        .frame(width: 150)
                        Stepper("", value: Binding(
                            get: { settingsDraft.sidebarLength },
                            set: { newValue in
                                stepSidebarLength(to: newValue)
                            }), in: Self.sidebarLengthRange, step: 1)
                        .labelsHidden()
                    }
                    Toggle(isOn: $settingsDraft.showBrugadaTriangle) {
                        Text("Show Brugada triangle", tableName: "Settings")
                    }
                } header: {
                    Text("Appearance", tableName: "Settings")
                        .font(.title)

                }
                Section {
                    Picker(selection: $settingsDraft.rounding) {
                        ForEach(Rounding.allCases, id: \.self) {
                            value in Text(value.localizedTitle).tag(value)
                        }
                    } label: {
                        Text("Round measurements", tableName: "Settings")
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
                        .font(.title)
                }
                Section {
                    TextField(text: $settingsDraft.timeCalibration) {
                        Text("Time calibration", tableName: "Settings")
                    }
                    .frame(width: 300)
                    TextField(text: $settingsDraft.amplitudeCalibration) {
                        Text("Amplitude calibration", tableName: "Settings")
                    }
                    .frame(width: 300)

                } header: {
                    Text("Calibration", tableName: "Settings")
                        .font(.title)
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
                        Text("Auto-position labels", tableName: "Settings")
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
                        .font(.title)
                }
                Section {
                    Toggle(isOn: $settingsDraft.deemphasizeMarchingComponents) {
                        Text("Dim marching components", tableName:    "Settings")
                    }
                    Picker(selection: $settingsDraft.numberOfMarchingComponents) {
                        ForEach(1...20, id: \.self) {
                            Text("\($0)")
                                .tag($0)
                        }
                    } label: {
                        Text("Number of marching components", tableName: "Settings")
                    }
                } header: {
                    Text("Marching Calipers", tableName: "Settings")
                        .font(.title)
                }
            }
        }
        .onAppear {
            updateSidebarLengthText()
        }
        .onDisappear {
            commitSidebarLengthText()
        }
    }

    private func commitSidebarLengthText() {
        guard let typedSidebarLength = parsedSidebarLengthText() else {
            updateSidebarLengthText()
            return
        }

        settingsDraft.sidebarLength = typedSidebarLength
        updateSidebarLengthText()
    }

    private func stepSidebarLength(to newValue: Int) {
        let step = newValue - settingsDraft.sidebarLength
        let baseSidebarLength = parsedSidebarLengthText() ?? settingsDraft.sidebarLength
        settingsDraft.sidebarLength = clampedSidebarLength(baseSidebarLength + step)
        updateSidebarLengthText()
    }

    private func parsedSidebarLengthText() -> Int? {
        parsedSidebarLength(from: sidebarLengthText)
    }

    private func updateSidebarLengthDraft(from text: String) {
        guard let value = parsedSidebarLength(from: text) else {
            return
        }

        settingsDraft.sidebarLength = value
    }

    private func parsedSidebarLength(from text: String) -> Int? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmedText) else {
            return nil
        }

        return clampedSidebarLength(value)
    }

    private func clampedSidebarLength(_ value: Int) -> Int {
        min(max(value, Self.sidebarLengthRange.lowerBound), Self.sidebarLengthRange.upperBound)
    }

    private func updateSidebarLengthText() {
        sidebarLengthText = "\(settingsDraft.sidebarLength)"
    }
}

struct NoteSettingsView: View {
    @Binding var settingsDraft: SettingsDraft
    @State private var noteTextBoxWidthText = ""
    @State private var noteTextBoxHeightText = ""

    private static let noteTextBoxWidthRange = 40...500
    private static let noteTextBoxHeightRange = 20...300

    private var noteTextBoxWidthTextBinding: Binding<String> {
        Binding(
            get: { noteTextBoxWidthText },
            set: { newValue in
                noteTextBoxWidthText = newValue
                updateNoteTextBoxWidthDraft(from: newValue)
            }
        )
    }

    private var noteTextBoxHeightTextBinding: Binding<String> {
        Binding(
            get: { noteTextBoxHeightText },
            set: { newValue in
                noteTextBoxHeightText = newValue
                updateNoteTextBoxHeightDraft(from: newValue)
            }
        )
    }

    var body: some View {
        Form {
            Picker(selection: $settingsDraft.noteTextFontSize) {
                ForEach(10...36, id: \.self) {
                    Text("\($0)")
                        .tag($0)
                }
            } label: {
                Text("Note text font size", tableName: "Settings")
            }
            ColorPicker(selection: $settingsDraft.noteTextColor) {
                Text("Note text color", tableName: "Settings")
            }
            HStack {
                Text("Note text box width", tableName: "Settings")
                TextField("Value", text: noteTextBoxWidthTextBinding, onEditingChanged: { isEditing in
                    if !isEditing {
                        commitNoteTextBoxWidthText()
                    }
                }, onCommit: {
                    commitNoteTextBoxWidthText()
                })
                .frame(width: 150)
                Stepper("", value: Binding(
                    get: { settingsDraft.noteTextBoxWidth },
                    set: { newValue in
                        stepNoteTextBoxWidth(to: newValue)
                    }), in: Self.noteTextBoxWidthRange, step: 1)
                .labelsHidden()
            }
            HStack {
                Text("Note text box height", tableName: "Settings")
                TextField("Value", text: noteTextBoxHeightTextBinding, onEditingChanged: { isEditing in
                    if !isEditing {
                        commitNoteTextBoxHeightText()
                    }
                }, onCommit: {
                    commitNoteTextBoxHeightText()
                })
                .frame(width: 150)
                Stepper("", value: Binding(
                    get: { settingsDraft.noteTextBoxHeight },
                    set: { newValue in
                        stepNoteTextBoxHeight(to: newValue)
                    }), in: Self.noteTextBoxHeightRange, step: 1)
                .labelsHidden()
            }
        }
        .onAppear {
            updateNoteTextBoxWidthText()
            updateNoteTextBoxHeightText()
        }
        .onDisappear {
            commitNoteTextBoxWidthText()
            commitNoteTextBoxHeightText()
        }
    }

    private func commitNoteTextBoxWidthText() {
        guard let typedWidth = parsedNoteTextBoxWidthText() else {
            updateNoteTextBoxWidthText()
            return
        }

        settingsDraft.noteTextBoxWidth = typedWidth
        updateNoteTextBoxWidthText()
    }

    private func commitNoteTextBoxHeightText() {
        guard let typedHeight = parsedNoteTextBoxHeightText() else {
            updateNoteTextBoxHeightText()
            return
        }

        settingsDraft.noteTextBoxHeight = typedHeight
        updateNoteTextBoxHeightText()
    }

    private func stepNoteTextBoxWidth(to newValue: Int) {
        let step = newValue - settingsDraft.noteTextBoxWidth
        let baseWidth = parsedNoteTextBoxWidthText() ?? settingsDraft.noteTextBoxWidth
        settingsDraft.noteTextBoxWidth = clampedNoteTextBoxWidth(baseWidth + step)
        updateNoteTextBoxWidthText()
    }

    private func stepNoteTextBoxHeight(to newValue: Int) {
        let step = newValue - settingsDraft.noteTextBoxHeight
        let baseHeight = parsedNoteTextBoxHeightText() ?? settingsDraft.noteTextBoxHeight
        settingsDraft.noteTextBoxHeight = clampedNoteTextBoxHeight(baseHeight + step)
        updateNoteTextBoxHeightText()
    }

    private func parsedNoteTextBoxWidthText() -> Int? {
        parsedNoteTextBoxWidth(from: noteTextBoxWidthText)
    }

    private func parsedNoteTextBoxHeightText() -> Int? {
        parsedNoteTextBoxHeight(from: noteTextBoxHeightText)
    }

    private func updateNoteTextBoxWidthDraft(from text: String) {
        guard let value = parsedNoteTextBoxWidth(from: text) else {
            return
        }

        settingsDraft.noteTextBoxWidth = value
    }

    private func updateNoteTextBoxHeightDraft(from text: String) {
        guard let value = parsedNoteTextBoxHeight(from: text) else {
            return
        }

        settingsDraft.noteTextBoxHeight = value
    }

    private func parsedNoteTextBoxWidth(from text: String) -> Int? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmedText) else {
            return nil
        }

        return clampedNoteTextBoxWidth(value)
    }

    private func parsedNoteTextBoxHeight(from text: String) -> Int? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmedText) else {
            return nil
        }

        return clampedNoteTextBoxHeight(value)
    }

    private func clampedNoteTextBoxWidth(_ value: Int) -> Int {
        min(max(value, Self.noteTextBoxWidthRange.lowerBound), Self.noteTextBoxWidthRange.upperBound)
    }

    private func clampedNoteTextBoxHeight(_ value: Int) -> Int {
        min(max(value, Self.noteTextBoxHeightRange.lowerBound), Self.noteTextBoxHeightRange.upperBound)
    }

    private func updateNoteTextBoxWidthText() {
        noteTextBoxWidthText = "\(settingsDraft.noteTextBoxWidth)"
    }

    private func updateNoteTextBoxHeightText() {
        noteTextBoxHeightText = "\(settingsDraft.noteTextBoxHeight)"
    }
}

struct PdfSettingsView: View {
    @Binding var settingsDraft: SettingsDraft

    var body: some View {
        Form {
            Picker(selection: $settingsDraft.pdfRenderScale) {
                ForEach(PdfRenderScale.allCases, id: \.self) { scale in
                    Text(scale.localizedTitle)
                        .tag(scale)
                }
            } label: {
                Text("PDF resolution", tableName: "Settings")
            }
            Toggle(isOn: $settingsDraft.clearCalipersBetweenPages) {
                Text("Clear calipers between pages", tableName: "Settings")
            }
            Toggle(isOn: $settingsDraft.recalibrateWhenChangingPages) {
                Text("Recalibrate calipers between pages", tableName: "Settings")
            }
            Toggle(isOn: $settingsDraft.resetImageZoomBetweenPages) {
                Text("Reset image zoom between pages", tableName: "Settings")
            }
            Toggle(isOn: $settingsDraft.resetImageRotationBetweenPages) {
                Text("Reset image rotation between pages", tableName: "Settings")
            }
        }
    }
}

#Preview {
    SettingsView(settingsDraft: .constant(SettingsDraft(Preferences.shared)))
        .padding(20)
        .frame(width: 650, height: 460)
}
