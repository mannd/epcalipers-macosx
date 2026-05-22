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
    // TODO: add all preferences

    init(_ preferences: Preferences) {
        transparency = preferences.transparency
        showSampleECG = preferences.showSampleECG
        // TODO: add all preferences
    }

    func apply(to preferences: Preferences) {
        preferences.transparency = transparency
        preferences.showSampleECG = showSampleECG
        // TODO: add all preferences
    }


}

struct SettingsView: View {
    @Binding var settingsDraft: SettingsDraft
    
    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                GeneralSettingsView()
            }
            Tab("Calipers", image: "custom-time-caliper") {
                CaliperSettingsView()
            }
            Tab("Notes", systemImage: "pencil.and.list.clipboard") {
                NoteSettingsView()
            }
            Tab("PDF", systemImage: "text.document") {
                PdfSettingsView()
            }
        }
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Text("Hello, World!")
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
