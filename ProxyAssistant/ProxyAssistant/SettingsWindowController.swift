//
//  SettingsWindowController.swift
//  ProxyAssistant
//
//  Created by Oleg Kr on 24.01.2026.
//

import Cocoa
import SwiftUI

final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func show() {
        if window == nil {
            let view = SettingsView()
            let hosting = NSHostingController(rootView: view)

            let w = NSWindow(contentViewController: hosting)
            w.title = "Settings"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.delegate = self
            window = w
        }

        // Set app regular.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Return menubar-only.
        NSApp.setActivationPolicy(.accessory)
    }
}
