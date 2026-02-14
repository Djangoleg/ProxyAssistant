//
//  AppDelegate.swift
//  ProxyAssistant
//
//  Created by Oleg Kr on 25.01.2026.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var enableProxyItem: NSMenuItem!
    var disableProxyItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // App icon image.
        let image = NSImage(systemSymbolName: "network", accessibilityDescription: nil)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.contentTintColor = nil

        let menu = NSMenu()
        menu.autoenablesItems = false

        enableProxyItem = NSMenuItem(
            title: "Enable Proxy",
            action: #selector(enableProxy),
            keyEquivalent: ""
        )

        disableProxyItem = NSMenuItem(
            title: "Disable Proxy",
            action: #selector(disableProxy),
            keyEquivalent: ""
        )

        menu.addItem(enableProxyItem)
        menu.addItem(disableProxyItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: ""))

        statusItem.menu = menu
        
        initCurrentState()
        updateMenuState()
    }
    
    private func initCurrentState() {
        let iface = UserDefaults.standard.string(forKey: "interface") ?? "Wi-Fi"
        let currentProxys = ProxyService.shared.getCurrentProxy(interface: iface)
        let currentProxy = currentProxys?.first
        print("currentProxy -> server = \(currentProxy?.ip ?? ""), port = \(currentProxy?.port ?? ""), protocol = \(currentProxy?.proto ?? "")")
        
        UserDefaults.standard.set(currentProxy?.ip, forKey: "proxyIP")
        UserDefaults.standard.set(currentProxy?.port, forKey: "proxyPort")
        UserDefaults.standard.set(currentProxy?.proto, forKey: "proxyProtocol")
        UserDefaults.standard.set(iface, forKey: "interface")
    }

    private func updateMenuState() {
        let iface = UserDefaults.standard.string(forKey: "interface") ?? "Wi-Fi"
        let anyEnabled = ProxyService.shared.isAnyProxyEnabled(interface: iface)
        
        enableProxyItem.isEnabled = !anyEnabled
        disableProxyItem.isEnabled = anyEnabled
        updateStatusIcon(isEnabled: anyEnabled)

        print("anyEnabled =", anyEnabled)
    }
    
    private func updateStatusIcon(isEnabled: Bool) {
        guard let button = statusItem.button else { return }

        let symbolName = isEnabled
            ? "network.badge.shield.half.filled"
            : "network"

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        image?.isTemplate = true

        button.image = image
    }
    
    @objc func enableProxy() {
        let ip = UserDefaults.standard.string(forKey: "proxyIP") ?? ""
        let port = UserDefaults.standard.string(forKey: "proxyPort") ?? ""
        let iface = UserDefaults.standard.string(forKey: "interface") ?? "Wi-Fi"
        let proto = UserDefaults.standard.string(forKey: "proxyProtocol") ?? "socks"

        ProxyService.shared.enableProxy(ip: ip, port: port, interface: iface, proto: proto)
        
        updateMenuState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.updateMenuState() }
    }

    @objc func disableProxy() {
        let iface = UserDefaults.standard.string(forKey: "interface") ?? "Wi-Fi"

        ProxyService.shared.disableProxy(interface: iface)
        
        updateMenuState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.updateMenuState() }
    }

    @objc func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
