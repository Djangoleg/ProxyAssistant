//
//  AutoLaunchService.swift
//  ProxyAssistant
//
//  Created by Oleg Kr on 14.02.2026.
//

import Foundation
import ServiceManagement

final class AutoLaunchService {
    static let shared = AutoLaunchService()
    private init() {}

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("AutoLaunch error:", error)
        }
    }

    func isEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
}
