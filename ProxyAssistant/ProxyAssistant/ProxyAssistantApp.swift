//
//  ProxyAssistantApp.swift
//  ProxyAssistant
//
//  Created by Oleg Kr on 24.01.2026.
//

import SwiftUI

@main
struct ProxyAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
