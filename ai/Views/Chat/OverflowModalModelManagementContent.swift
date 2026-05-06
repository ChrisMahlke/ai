//
//  OverflowModalModelManagementContent.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ModelManagementContent: View {
    let activeModelProfile: LocalModelProfile
    let installedModels: [InstalledLocalModel]
    let selectModelProfile: (LocalModelProfile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ModalPanel {
                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle("Installed models")

                    VStack(spacing: 8) {
                        ForEach(installedModels) { model in
                            modelRow(model)
                        }
                    }
                }
            }

            ModalPanel {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle("Install")

                    Text("Add GGUF files to `ai/Models`, include them in the app target, then rebuild. Keep only the models you need in the target because each bundled model increases app size and memory pressure.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(AppTheme.foreground.opacity(0.58))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(LocalModelProfile.allCases) { profile in
                            Text(profile.installationNote)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundStyle(AppTheme.foreground.opacity(0.44))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func modelRow(_ model: InstalledLocalModel) -> some View {
        let isActive = model.profile == activeModelProfile

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: model.isInstalled ? "checkmark.circle.fill" : "arrow.down.circle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(model.isInstalled ? .green.opacity(0.82) : AppTheme.foreground.opacity(0.32))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(model.profile.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.foreground.opacity(0.9))

                    if isActive {
                        Text("Active")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryActionText.opacity(0.78))
                            .padding(.horizontal, 7)
                            .frame(height: 20)
                            .background(AppTheme.primaryAction.opacity(0.88))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }

                Text(model.profile.subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppTheme.foreground.opacity(0.48))
                    .fixedSize(horizontal: false, vertical: true)

                Text(model.isInstalled ? byteString(model.fileSizeBytes) : model.statusText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppTheme.foreground.opacity(0.38))
                    .lineLimit(3)
            }

            Spacer(minLength: 10)

            Button {
                selectModelProfile(model.profile)
            } label: {
                Text(isActive ? "Selected" : "Use")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 72, height: 36)
                    .background(model.isInstalled && !isActive ? AppTheme.primaryAction : AppTheme.foreground.opacity(0.1))
                    .foregroundStyle(model.isInstalled && !isActive ? AppTheme.primaryActionText : AppTheme.foreground.opacity(0.46))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!model.isInstalled || isActive)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isActive ? AppTheme.elevatedFill : AppTheme.panelFill)
                .stroke(isActive ? AppTheme.panelStroke.opacity(1.35) : AppTheme.panelStroke.opacity(0.75), lineWidth: 1)
        )
    }

    private func byteString(_ bytes: UInt64) -> String {
        guard bytes > 0 else { return "Unknown size" }

        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}
