//
//  OverflowModalDiagnosticsContent.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct DiagnosticsExportContent: View {
    let report: String
    let copyDiagnostics: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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
}
