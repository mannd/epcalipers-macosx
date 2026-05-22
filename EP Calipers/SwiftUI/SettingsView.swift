//
//  SettingsView.swift
//  EP Calipers
//
//  Created by David Mann on 5/22/26.
//  Copyright © 2026 EP Studios. All rights reserved.
//

import SwiftUI

struct SettingsDraft {
    var transparency: Bool
    var showSampleECG: Bool
    var showPrompts: Bool
    var qtcFormula: QTcFormulaPreference
    var numberOfQTcMeanRRIntervals: Int
    var numberOfMeanRRIntervals: Int
    // TODO: add all preferences

    init(_ preferences: Preferences) {
        transparency = preferences.transparency
        showSampleECG = preferences.showSampleECG
        showPrompts = preferences.showPrompts
        qtcFormula = preferences.qtcFormula
        numberOfQTcMeanRRIntervals = preferences.defaultNumberOfQTcMeanRRIntervals
        numberOfMeanRRIntervals = preferences.defaultNumberOfMeanRRIntervals
        // TODO: add all preferences
    }

    func apply(to preferences: Preferences) {
        preferences.transparency = transparency
        preferences.showSampleECG = showSampleECG
        preferences.qtcFormula = qtcFormula
        preferences.defaultNumberOfQTcMeanRRIntervals = numberOfQTcMeanRRIntervals
        preferences.defaultNumberOfMeanRRIntervals = numberOfMeanRRIntervals
        // TODO: add all preferences
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
            CaliperSettingsView()
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
        }
    }
}

struct CaliperSettingsView: View {
    var body: some View {
        Form {
            Text("Hello, World!")
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
}
