//
//  OnboardingView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct OnboardingView: View {
    let installedModels: [InstalledLocalModel]
    let complete: () -> Void

    private var hasInstalledModel: Bool {
        installedModels.contains { $0.isInstalled }
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 10) {
                    Text("ai")
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .textCase(.lowercase)

                    Text("Private, local-first chat on iPhone and iPad.")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    onboardingRow(
                        icon: "iphone",
                        title: "Runs locally by default",
                        text: "The default provider uses an open-weight GGUF model in the app bundle."
                    )

                    onboardingRow(
                        icon: hasInstalledModel ? "checkmark.circle" : "exclamationmark.triangle",
                        title: hasInstalledModel ? "Model found" : "Model required",
                        text: hasInstalledModel
                        ? "At least one local model profile is installed and ready to load."
                        : "Add google_gemma-3-1b-it-Q4_K_M.gguf to ai/Models and include it in the app target."
                    )

                    onboardingRow(
                        icon: "memorychip",
                        title: "Memory aware",
                        text: "Use Efficient settings on older or warm devices. The app unloads the model in the background."
                    )
                }

                Spacer(minLength: 24)

                Button(action: complete) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the chat screen")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 520)
        }
        .foregroundStyle(.white)
    }

    private func onboardingRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))

                Text(text)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.52))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
