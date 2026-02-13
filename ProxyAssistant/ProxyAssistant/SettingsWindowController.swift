//
//  SettingsWindowController.swift
//  ProxyAssistant
//
//  Created by Oleg Kr on 24.01.2026.
//

import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {

    static let shared = SettingsWindowController()

    private init() {
        let view = SettingsView()
        let hosting = NSHostingController(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "Settings"
        window.contentView = hosting.view

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
