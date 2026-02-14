//
//  SettingsView.swift
//  ProxyAssistant
//
//  Created by Oleg Kr on 24.01.2026.
//

import SwiftUI

struct SettingsView: View {
    @State private var proxyIP: String = UserDefaults.standard.string(forKey: "proxyIP") ?? ""
    @State private var proxyPort: String = UserDefaults.standard.string(forKey: "proxyPort") ?? ""
    @State private var interface: String = UserDefaults.standard.string(forKey: "interface") ?? "Wi-Fi"
    @State private var proto: String = UserDefaults.standard.string(forKey: "proxyProtocol") ?? "socks"

    let interfaces = ["Wi-Fi", "Ethernet", "Thunderbolt Bridge"]
    let protocols = ["socks", "http", "https"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Proxy IP:")
                TextField("127.0.0.1", text: $proxyIP)
                    .frame(width: 200)
            }

            HStack {
                Text("Port:")
                TextField("8888", text: $proxyPort)
                    .frame(width: 80)
            }

            HStack {
                Text("Interface:")
                Picker("", selection: $interface) {
                    ForEach(interfaces, id: \.self) { item in
                        Text(item)
                    }
                }
                .frame(width: 200)
            }
            
            HStack {
                Text("Protocol:")
                Picker("", selection: $proto) {
                    ForEach(protocols, id: \.self) { item in
                        Text(item)
                    }
                }
                .frame(width: 125)
            }

            HStack {
                Button("Save") { save() }
                Button("Cancel") {
                    NSApp.keyWindow?.close()
                }
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding(20)
        .frame(width: 340, height: 200)
    }

    func save() {
        UserDefaults.standard.set(proxyIP, forKey: "proxyIP")
        UserDefaults.standard.set(proxyPort, forKey: "proxyPort")
        UserDefaults.standard.set(interface, forKey: "interface")
        UserDefaults.standard.set(proto, forKey: "proxyProtocol")
        
        NSApp.keyWindow?.close()
    }
}

#Preview {
    SettingsView()
}
