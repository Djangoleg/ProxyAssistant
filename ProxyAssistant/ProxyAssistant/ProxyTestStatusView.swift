//
//  ProxyTestStatusView.swift
//  ProxyAssistant
//
//  Created by Oleg Kr on 15.02.2026.
//

import SwiftUI

struct ProxyTestStatusView: View {

    enum Mode {
        case direct
        case proxy
    }

    let isTesting: Bool
    let ok: String?
    let err: String?
    let mode: Mode?

    var body: some View {
        Group {
            if isTesting {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Testing...")
                }
            } else if let ok {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        if let mode {
                            Text(mode == .proxy ? "Via proxy" : "Direct")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("External IP: \(ok)")
                    }
                }
            } else if let err {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)

                    VStack(alignment: .leading, spacing: 2) {
                        if let mode {
                            Text(mode == .proxy ? "Via proxy" : "Direct")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(err)
                    }
                }
            }
        }
        .animation(.default, value: isTesting)
    }
}
