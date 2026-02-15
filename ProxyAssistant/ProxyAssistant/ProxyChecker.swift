//
//  ProxyChecker.swift
//  ProxyAssistant
//
//  Created by Oleg Kr on 14.02.2026.
//

import Foundation

enum ProxyTestError: Error {
    case invalidURL
    case invalidPort
    case emptyIP
    case badResponse
}

final class ProxyChecker {
    static let shared = ProxyChecker()
    private init() {}

    func testProxy(ip: String, port: String, proto: String, testUrl: String) async -> Result<String, Error> {
        let ip = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        let portStr = port.trimmingCharacters(in: .whitespacesAndNewlines)
        let proto = proto.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let testUrl = testUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !ip.isEmpty else { return .failure(ProxyTestError.emptyIP) }
        guard let port = Int(portStr), (1...65535).contains(port) else { return .failure(ProxyTestError.invalidPort) }

        guard let url = URL(string: testUrl),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return .failure(ProxyTestError.invalidURL) }

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 6
        config.timeoutIntervalForResource = 8

        var proxyDict: [AnyHashable: Any] = [:]

        switch proto {
        case "http":
            proxyDict[kCFNetworkProxiesHTTPEnable as String] = 1
            proxyDict[kCFNetworkProxiesHTTPProxy as String] = ip
            proxyDict[kCFNetworkProxiesHTTPPort as String] = port

        case "https":
            proxyDict[kCFNetworkProxiesHTTPSEnable as String] = 1
            proxyDict[kCFNetworkProxiesHTTPSProxy as String] = ip
            proxyDict[kCFNetworkProxiesHTTPSPort as String] = port

        case "socks":
            proxyDict[kCFNetworkProxiesSOCKSEnable as String] = 1
            proxyDict[kCFNetworkProxiesSOCKSProxy as String] = ip
            proxyDict[kCFNetworkProxiesSOCKSPort as String] = port

        default:
            return .failure(NSError(
                domain: "ProxyTester",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Unknown protocol: \(proto)"]
            ))
        }

        config.connectionProxyDictionary = proxyDict

        let session = URLSession(configuration: config)

        do {
            let (data, resp) = try await session.data(from: url)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return .failure(ProxyTestError.badResponse)
            }

            let text = String(decoding: data, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return .success(text)

        } catch {
            if let e = error as? URLError {
                let msg: String
                switch e.code {
                case .notConnectedToInternet, .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
                    msg = "Cannot reach the test URL through proxy. Check IP/Port and ensure the proxy server is running."
                case .timedOut:
                    msg = "Proxy test timed out. Check IP/Port and proxy availability."
                default:
                    msg = e.localizedDescription
                }
                return .failure(NSError(domain: "ProxyTester", code: e.errorCode,
                                        userInfo: [NSLocalizedDescriptionKey: msg]))
            }
            return .failure(error)
        }
    }
    
    func testDirect(testUrl: String) async -> Result<String, Error> {
        let testUrl = testUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: testUrl),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return .failure(ProxyTestError.invalidURL) }

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 6
        config.timeoutIntervalForResource = 8

        let session = URLSession(configuration: config)

        do {
            let (data, resp) = try await session.data(from: url)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return .failure(ProxyTestError.badResponse)
            }
            let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            return .success(text)
        } catch {
            return .failure(error)
        }
    }
}
