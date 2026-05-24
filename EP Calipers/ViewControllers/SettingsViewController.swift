//
//  SettingsViewController.swift
//  EP Calipers
//
//  Created by David Mann on 5/22/26.
//  Copyright © 2026 EP Studios. All rights reserved.
//

import AppKit
import SwiftUI

final class SettingsViewController: NSViewController, NSWindowDelegate {
    private let appPreferences: Preferences
    private let settingsStore: SettingsDraftStore
    private weak var mainWindowController: MainWindowController?
    private var isClosingModalWindow = false

    init(preferences: Preferences = Preferences.shared, mainWindowController: MainWindowController? = nil) {
        self.appPreferences = preferences
        self.settingsStore = SettingsDraftStore(settingsDraft: SettingsDraft(preferences))
        self.mainWindowController = mainWindowController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.appPreferences = Preferences.shared
        self.settingsStore = SettingsDraftStore(settingsDraft: SettingsDraft(Preferences.shared))
        super.init(coder: coder)
    }

    override func loadView() {
        let rootView = NSView()

        let hostingView = NSHostingView(rootView: SettingsRootView(settingsStore: settingsStore))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.sizingOptions = []

        let cancelButton = NSButton(title: NSLocalizedString("Cancel", comment: ""), target: self, action: #selector(cancelSettings(_:)))
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.keyEquivalent = "\u{1b}"

        let okButton = NSButton(title: NSLocalizedString("OK", comment: ""), target: self, action: #selector(applySettings(_:)))
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.keyEquivalent = "\r"
        okButton.bezelStyle = .rounded

        let buttonStack = NSStackView(views: [cancelButton, okButton])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.spacing = 8

        rootView.addSubview(hostingView)
        rootView.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: rootView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -16),

            buttonStack.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -16),

            rootView.widthAnchor.constraint(greaterThanOrEqualToConstant: 600),
            rootView.heightAnchor.constraint(greaterThanOrEqualToConstant: 760)
        ])

        view = rootView
    }

    func showModalWindow() {
        let window = NSWindow(contentViewController: self)
        window.title = NSLocalizedString("Settings", comment: "")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()

        NSApp.runModal(for: window)
    }

    @IBAction func openSwiftUIWindow(_ sender: Any) {
        showModalWindow()
    }

    @objc private func applySettings(_ sender: Any) {
        let previousTransparency = appPreferences.transparency
        settingsStore.settingsDraft.apply(to: appPreferences)
        appPreferences.save()
        mainWindowController?.settingsDidChange(previousTransparency: previousTransparency)
        closeModalWindow(response: .OK)
    }

    @objc private func cancelSettings(_ sender: Any) {
        closeModalWindow(response: .cancel)
    }

    private func closeModalWindow(response: NSApplication.ModalResponse) {
        isClosingModalWindow = true
        NSApp.stopModal(withCode: response)
        view.window?.close()
        isClosingModalWindow = false
    }

    func windowWillClose(_ notification: Notification) {
        if !isClosingModalWindow {
            NSApp.stopModal(withCode: .cancel)
        }
    }
}

private final class SettingsDraftStore: ObservableObject {
    @Published var settingsDraft: SettingsDraft

    init(settingsDraft: SettingsDraft) {
        self.settingsDraft = settingsDraft
    }
}

private struct SettingsRootView: View {
    @ObservedObject var settingsStore: SettingsDraftStore

    var body: some View {
        SettingsView(settingsDraft: $settingsStore.settingsDraft)
            .padding(20)
    }
}
