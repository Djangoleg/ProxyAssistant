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
    
    private var refreshTimer: Timer?
    private var lastAnyEnabled: Bool?
    private var proxyHealthTask: Task<Void, Never>?

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
        
        ensureDefaults()
        updateMenuState()
        startAutoRefresh()
        NotificationService.shared.requestPermissionIfNeeded()
        checkProxyOnStartup()
        testProxyOnceAndNotifyIfFailIfEnabledAtStartup()
    }
    
    private func testProxyOnceAndNotifyIfFailIfEnabledAtStartup() {
        let iface = UserDefaults.standard.string(forKey: "interface") ?? "Wi-Fi"
        let anyEnabled = ProxyService.shared.isAnyProxyEnabled(interface: iface)
        guard anyEnabled else { return }
        testProxyOnceAndNotifyIfFail()
    }
    
    private func checkProxyOnStartup() {
        let d = UserDefaults.standard
        let ip = d.string(forKey: "ip") ?? ""
        let port = d.string(forKey: "port") ?? ""
        let proto = d.string(forKey: "protocol") ?? "socks"
        let iface = d.string(forKey: "interface") ?? "Wi-Fi"
        let testUrl = d.string(forKey: "testUrl") ?? "https://ifconfig.co/ip"

        // We only check if the proxy is actually enabled in the system (otherwise we don't spam).
        let anyEnabled = ProxyService.shared.isAnyProxyEnabled(interface: iface)
        guard anyEnabled else { return }

        Task {
            let res = await ProxyChecker.shared.testProxy(ip: ip, port: port, proto: proto, testUrl: testUrl)
            switch res {
            case .success:
                break
            case .failure(let err):
                NotificationService.shared.notify(
                    title: "Proxy seems down",
                    body: "\(proto.uppercased()) \(ip):\(port)\n\(err.localizedDescription)"
                )
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            self?.updateMenuState()
        }
        RunLoop.main.add(refreshTimer!, forMode: .common)
    }
    
    private func ensureDefaults() {
        let d = UserDefaults.standard

        if d.string(forKey: "interface") == nil {
            d.set("Wi-Fi", forKey: "interface")
        }
        if d.string(forKey: "protocol") == nil {
            d.set("socks", forKey: "protocol")
        }
        if d.string(forKey: "ip") == nil {
            d.set("127.0.0.1", forKey: "ip")
        }
        if d.string(forKey: "port") == nil {
            d.set("1080", forKey: "port")
        }
        if d.string(forKey: "testUrl") == nil {
            d.set("https://ifconfig.co/ip", forKey: "testUrl")
        }
    }
    
    private func updateMenuState() {
        let iface = UserDefaults.standard.string(forKey: "interface") ?? "Wi-Fi"
        let anyEnabled = ProxyService.shared.isAnyProxyEnabled(interface: iface)

        enableProxyItem.isEnabled = !anyEnabled
        disableProxyItem.isEnabled = anyEnabled
        updateStatusIcon(isEnabled: anyEnabled)

        updateToolTip(interface: iface, anyEnabled: anyEnabled)

        if lastAnyEnabled == nil {
            lastAnyEnabled = anyEnabled
        } else if lastAnyEnabled != anyEnabled {
            lastAnyEnabled = anyEnabled
            if anyEnabled {
                testProxyOnceAndNotifyIfFail()
            }
        }
    }
    
    private func testProxyOnceAndNotifyIfFail() {
        // Cancel the previous test if it is still running.
        proxyHealthTask?.cancel()

        let d = UserDefaults.standard
        let ip = d.string(forKey: "ip") ?? ""
        let port = d.string(forKey: "port") ?? ""
        let proto = d.string(forKey: "protocol") ?? "socks"
        let testUrl = d.string(forKey: "testUrl") ?? "https://ifconfig.co/ip"

        proxyHealthTask = Task {
            // Short delay: allow the system to apply the proxy.
            try? await Task.sleep(nanoseconds: 400_000_000)

            let res = await ProxyChecker.shared.testProxy(ip: ip, port: port, proto: proto, testUrl: testUrl)
            if Task.isCancelled { return }

            switch res {
            case .success:
                break
            case .failure(let err):
                NotificationService.shared.notify(
                    title: "Proxy seems down",
                    body: "\(proto.uppercased()) \(ip):\(port)\n\(err.localizedDescription)"
                )
            }
        }
    }
    
    private func updateToolTip(interface: String, anyEnabled: Bool) {
        guard let button = statusItem.button else { return }

        guard anyEnabled else {
            button.toolTip = "Proxy: Off"
            return
        }

        let items = ProxyService.shared.getCurrentProxy(interface: interface) ?? []
        if items.isEmpty {
            button.toolTip = "Proxy: On"
            return
        }
        
        // Show all.
        let text = items
            .map { "\($0.proto.uppercased()) \($0.ip):\($0.port)" }
            .joined(separator: "\n")

        button.toolTip = text
    }
    
    private func updateStatusIcon(isEnabled: Bool) {
        guard let button = statusItem.button else { return }

        let symbolName = isEnabled
            ? "network.badge.shield.half.filled"
            : "network"
        
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        
        image?.isTemplate = true

        button.image = image
    }
    
    @objc func enableProxy() {
        let ip = UserDefaults.standard.string(forKey: "ip") ?? ""
        let port = UserDefaults.standard.string(forKey: "port") ?? ""
        let iface = UserDefaults.standard.string(forKey: "interface") ?? "Wi-Fi"
        let proto = UserDefaults.standard.string(forKey: "protocol") ?? "socks"

        ProxyService.shared.enableProxy(ip: ip, port: port, interface: iface, proto: proto)
        updateMenuState()
    }

    @objc func disableProxy() {
        let iface = UserDefaults.standard.string(forKey: "interface") ?? "Wi-Fi"
        
        ProxyService.shared.disableProxy(interface: iface)
        updateMenuState()
    }

    @objc func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
