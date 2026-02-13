//
//  ProxyService.swift
//  ProxyAssistant
//
//  Created by Oleg Kr on 25.01.2026.
//

import Foundation
import SwiftUI
import Darwin

final class ProxyService {
    static let shared = ProxyService()
    private init() {}

    // MARK: - Run commands
    
    private func runCommand(args: [String]) -> (exit: Int32, output: String) {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = args

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
        } catch {
            return (-1, "ERR: failed to start networksetup: \(error)")
        }

        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let text = String(decoding: data, as: UTF8.self)
        return (task.terminationStatus, text)
    }

    private func runCommandWithOutput(args: [String]) -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = args

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - State checks

    func isAnyProxyEnabled(interface: String) -> Bool {
        let http = runCommandWithOutput(args: ["-getwebproxy", interface]).contains("Enabled: Yes")
        let https = runCommandWithOutput(args: ["-getsecurewebproxy", interface]).contains("Enabled: Yes")
        let socks = runCommandWithOutput(args: ["-getsocksfirewallproxy", interface]).contains("Enabled: Yes")
        return http || https || socks
    }
    
    // MARK: - Current proxy
    
    func getCurrentProxy(interface: String) -> Array<(ip: String, port: String, proto: String)>? {
        
        var proxyInfo: [(ip: String, port: String, proto: String)] = []
        
        let getwebproxy = runCommandWithOutput(args: ["-getwebproxy", interface])
        
        if getwebproxy.contains("Enabled: Yes")
        {
            let lines = getwebproxy.split(separator: "\n")
            if let item = getIpAndPortFromLines(lines: lines, proto: "http") {
                proxyInfo.append(item)
            }
        }
        
        let getsecurewebproxy = runCommandWithOutput(args: ["-getsecurewebproxy", interface])
        
        if getsecurewebproxy.contains("Enabled: Yes")
        {
            let lines = getsecurewebproxy.split(separator: "\n")
            if let item = getIpAndPortFromLines(lines: lines, proto: "https") {
                proxyInfo.append(item)
            }
        }
        
        let getsocksfirewallproxy = runCommandWithOutput(args: ["-getsocksfirewallproxy", interface])
        
        if getsocksfirewallproxy.contains("Enabled: Yes")
        {
            let lines = getsocksfirewallproxy.split(separator: "\n")
            if let item = getIpAndPortFromLines(lines: lines, proto: "socks") {
                proxyInfo.append(item)
            }
        }
        
        return proxyInfo;
    }
    
    func getIpAndPortFromLines(lines: Array<Substring>, proto: String) -> (ip: String, port: String, proto: String)? {
        
        var proxyInfo: (ip: String, port: String, proto: String)? = ("", "", proto)
        
        for line in lines
        {
            if line.hasPrefix("Server:") {
                proxyInfo?.ip = line.components(separatedBy: "Server:").last?.trimmingCharacters(in: .whitespaces) ?? ""
            }
            else if line.hasPrefix("Port:") {
                proxyInfo?.port = line.components(separatedBy: "Port:").last?.trimmingCharacters(in: .whitespaces) ?? ""
            }
        }
        
        return proxyInfo
    }

    // MARK: - Enable/disable logic
    
    func disableProxy(interface: String) {
        let cmds: [[String]] = [
            ["-setwebproxystate", interface, "off"],
            ["-setsecurewebproxystate", interface, "off"],
            ["-setsocksfirewallproxystate", interface, "off"]
        ]

        for c in cmds {
            let r = runCommand(args: c)
            if r.exit != 0 {
                print("networksetup failed:", c.joined(separator: " "), "\n", r.output)
            }
        }
    }
    
    func enableProxy(ip: String, port: String, interface: String, proto: String) {
        guard !ip.isEmpty, !port.isEmpty else { return }

        let p = proto.lowercased()
        let cmds: [[String]]

        switch p {
        case "http":
            cmds = [
                ["-setwebproxy", interface, ip, port],
                ["-setwebproxystate", interface, "on"]
            ]
        case "https":
            cmds = [
                ["-setsecurewebproxy", interface, ip, port],
                ["-setsecurewebproxystate", interface, "on"]
            ]
        case "socks":
            cmds = [
                ["-setsocksfirewallproxy", interface, ip, port],
                ["-setsocksfirewallproxystate", interface, "on"]
            ]
        default:
            print("Unknown proto:", proto)
            return
        }

        for c in cmds {
            let r = runCommand(args: c)
            if r.exit != 0 {
                print("networksetup failed:", c.joined(separator: " "), "\n", r.output)
            }
        }
    }
}
