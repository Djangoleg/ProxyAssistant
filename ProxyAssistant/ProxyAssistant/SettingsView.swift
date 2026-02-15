//
//  SettingsView.swift
//  ProxyAssistant
//
//  Created by Oleg Kr on 24.01.2026.
//

import SwiftUI

struct SettingsView: View {

    // Saved
    @AppStorage("ip") private var savedIP = "127.0.0.1"
    @AppStorage("port") private var savedPort = "1080"
    @AppStorage("interface") private var savedInterface = "Wi-Fi"
    @AppStorage("protocol") private var savedProto = "socks"
    @AppStorage("testUrl") private var savedTestUrl = "https://ifconfig.co/ip"
    @AppStorage("launchAtLogin") private var savedLaunchAtLogin = false

    // Draft
    @State private var ip: String = ""
    @State private var port: String = ""
    @State private var iface: String = ""
    @State private var proto: String = ""
    @State private var testUrl: String = ""
    @State private var launchAtLogin: Bool = false

    @State private var isTesting = false
    @State private var testResultText: String? = nil
    @State private var testErrorText: String? = nil

    // Save enabled only when changed
    @State private var isDirty = false
    
    @State private var currentTestMode: TestMode? = nil
    
    @State private var isLoading = true

    let interfaces = ["Wi-Fi", "Ethernet", "Thunderbolt Bridge"]
    let protocols = ["socks", "http", "https"]
    
    enum TestMode {
        case direct
        case proxy
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Proxy IP:")
                TextField("127.0.0.1", text: $ip)
                    .frame(width: 200)
            }

            HStack {
                Text("Port:")
                TextField("1080", text: $port)
                    .frame(width: 80)
            }

            HStack {
                Text("Interface:")
                Picker("", selection: $iface) {
                    ForEach(interfaces, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
                .frame(width: 200)
            }

            HStack {
                Text("Protocol:")
                Picker("", selection: $proto) {
                    ForEach(protocols, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
                .frame(width: 125)
            }

            HStack {
                Text("Test URL:")
                TextField("https://ifconfig.co/ip", text: $testUrl)
                    .frame(width: 240)
            }

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) {
                    AutoLaunchService.shared.setEnabled(launchAtLogin)
                    if !isLoading { isDirty = true }
                }

            HStack {
                Button("Test") { test() }
                    .disabled(isTesting)

                Button("Save") { save() }
                    .disabled(!isDirty)

                Button("Close") {
                    NSApp.keyWindow?.close()
                }
            }
            .padding(.top, 10)
            
            Spacer()
            
            ProxyTestStatusView(
                isTesting: isTesting,
                ok: testResultText,
                err: testErrorText,
                mode: currentTestMode.map {
                    $0 == .proxy ? .proxy : .direct
                }
            )

            Spacer()
        }
        .padding(20)
        .frame(width: 380, height: 350)
        .onAppear {
            // load saved → draft
            ip = savedIP
            port = savedPort
            iface = savedInterface
            proto = savedProto
            testUrl = savedTestUrl

            let systemLaunch = AutoLaunchService.shared.isEnabled()
            launchAtLogin = systemLaunch
            savedLaunchAtLogin = systemLaunch

            if !interfaces.contains(iface) { iface = interfaces.first ?? "Wi-Fi" }
            if !protocols.contains(proto) { proto = protocols.first ?? "socks" }

            testResultText = nil
            testErrorText = nil
            isTesting = false

            isDirty = false
            
            DispatchQueue.main.async {
                isLoading = false
            }
        }
        .onChange(of: ip) { if !isLoading { isDirty = true } }
        .onChange(of: port) { if !isLoading { isDirty = true } }
        .onChange(of: iface) { if !isLoading { isDirty = true } }
        .onChange(of: proto) { if !isLoading { isDirty = true } }
        .onChange(of: testUrl) { if !isLoading { isDirty = true } }
    }

    private func test() {
        testResultText = nil
        testErrorText = nil
        isTesting = true

        let systemProxyEnabled = ProxyService.shared.isAnyProxyEnabled(interface: iface)

        Task {
            let res: Result<String, Error>

            if systemProxyEnabled {
                currentTestMode = .proxy
                res = await ProxyChecker.shared.testProxy(
                    ip: ip,
                    port: port,
                    proto: proto,
                    testUrl: testUrl
                )
            } else {
                currentTestMode = .direct
                res = await ProxyChecker.shared.testDirect(testUrl: testUrl)
            }

            await MainActor.run {
                isTesting = false

                switch res {
                case .success(let text):
                    testResultText = text
                case .failure(let error):
                    testErrorText = error.localizedDescription
                }
            }
        }
    }

    private func save() {
        savedIP = ip
        savedPort = port
        savedInterface = iface
        savedProto = proto
        savedTestUrl = testUrl
        savedLaunchAtLogin = launchAtLogin

        isDirty = false

        testResultText = nil
        testErrorText = nil
    }
}

#Preview {
    SettingsView()
}
