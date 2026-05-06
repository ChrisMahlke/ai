//
//  OverflowModalDiagnosticsContent.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct DiagnosticsExportContent: View {
    let report: String
    let diagnostics: LocalModelDiagnostics
    let providerStatus: ProviderStatus
    let copyDiagnostics: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ModalPanel {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        SectionTitle("Current status")

                        Spacer()

                        ProviderHealthBadge(status: providerStatus)
                    }

                    VStack(spacing: 10) {
                        DiagnosticRow(label: "Provider", value: providerStatus.provider.title)
                        DiagnosticRow(label: "Status", value: providerStatus.title)
                        DiagnosticRow(label: "Model", value: diagnostics.modelName)
                        DiagnosticRow(label: "File", value: diagnostics.fileName)
                        DiagnosticRow(label: "Size", value: byteString(diagnostics.fileSizeBytes))
                        DiagnosticRow(label: "Thermal", value: thermalText(diagnostics.thermalState))

                        if let loadDuration = diagnostics.loadDuration {
                            DiagnosticRow(label: "Last load", value: String(format: "%.1fs", loadDuration))
                        }
                    }
                }
            }

            ModalPanel {
                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle("Rolling telemetry")

                    VStack(spacing: 10) {
                        DiagnosticRow(label: "Avg load", value: durationText(diagnostics.telemetry.averageLoadDuration))
                        DiagnosticRow(label: "Avg first token", value: durationText(diagnostics.telemetry.averageFirstTokenLatency))
                        DiagnosticRow(label: "Avg tokens/sec", value: rateText(diagnostics.telemetry.averageTokensPerSecond))
                        DiagnosticRow(label: "Failures", value: failureText)
                    }

                    Text("Stored only on this device and capped to recent local inference samples.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppTheme.foreground.opacity(0.46))
                }
            }

            ModalPanel {
                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle("Repair steps")

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(repairSteps, id: \.self) { step in
                            Label(step, systemImage: "wrench.and.screwdriver")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(AppTheme.foreground.opacity(0.68))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            ModalPanel {
                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle("Report")

                    Text("This report avoids chat content and user identifiers. It includes model status, memory, thermal state, selected provider, and installed model summary.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(AppTheme.foreground.opacity(0.58))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(report)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(AppTheme.foreground.opacity(0.68))
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.panelFill)
                        )

                    Button(action: copyDiagnostics) {
                        Text("Copy diagnostics")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(AppTheme.primaryAction)
                            .foregroundStyle(AppTheme.primaryActionText)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var failureText: String {
        guard diagnostics.telemetry.generationCount > 0 else { return "No samples" }

        return "\(diagnostics.telemetry.failureCount) of \(diagnostics.telemetry.generationCount) (\(Int((diagnostics.telemetry.failureRate * 100).rounded()))%)"
    }

    private var repairSteps: [String] {
        switch providerStatus.health {
        case .ready:
            return [
                "If responses slow down, switch to Efficient settings and run Test.",
                "If the device is warm, wait for thermal state to return to Nominal or Fair."
            ]
        case .loading:
            return [
                "Keep the app in the foreground until loading finishes.",
                "If loading stalls, stop generation, reopen diagnostics, and retry."
            ]
        case .unavailable, .notConfigured:
            return [
                "Open Models and confirm the selected model file is installed.",
                "Use Efficient settings, then Validate and Test.",
                "Restart the app if memory pressure recently unloaded the model."
            ]
        case .unknown:
            return [
                "Tap Test to force a local model load and settings check.",
                "Open Models if the selected profile does not match the bundled file."
            ]
        }
    }

    private func byteString(_ bytes: UInt64) -> String {
        guard bytes > 0 else { return "Unknown" }

        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    private func durationText(_ duration: TimeInterval?) -> String {
        guard let duration else { return "No samples" }

        return String(format: "%.2fs", duration)
    }

    private func rateText(_ rate: Double?) -> String {
        guard let rate else { return "No samples" }

        return String(format: "%.1f", rate)
    }

    private func thermalText(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:
            return "Nominal"
        case .fair:
            return "Fair"
        case .serious:
            return "Serious"
        case .critical:
            return "Critical"
        @unknown default:
            return "Unknown"
        }
    }
}
