//
//  ChatComposerView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ChatComposerView: View {
    @Binding var prompt: String
    @Binding var isFocused: Bool
    @Binding var inputHeight: CGFloat

    let canSend: Bool
    let isThinking: Bool
    let isGenerating: Bool
    let isResponseActive: Bool
    let generationMetrics: GenerationMetrics
    let canRegenerate: Bool
    let send: () -> Void
    let stop: () -> Void
    let regenerate: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 12) {
                inputBox

                Button(action: isResponseActive ? stop : send) {
                    Image(systemName: isResponseActive ? "stop.fill" : "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 42, height: 42)
                        .background(buttonBackground)
                        .foregroundStyle(buttonForeground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .disabled(!isResponseActive && !canSend)
                .accessibilityLabel(isResponseActive ? "Stop response" : "Send message")
                .accessibilityHint(isResponseActive ? "Stops the current generation" : "Sends the typed message")
            }

            HStack(spacing: 10) {
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.foreground.opacity(0.46))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if canRegenerate {
                    Button(action: regenerate) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 28, height: 24)
                            .background(AppTheme.subtleFill)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.foreground.opacity(0.58))
                    .accessibilityLabel("Regenerate last response")
                    .accessibilityHint("Runs the last user message again with current settings")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .background(
            Rectangle()
                .fill(AppTheme.background)
                .shadow(color: AppTheme.composerShadow, radius: 16, y: -8)
        )
    }

    private var buttonBackground: Color {
        if isResponseActive {
            return AppTheme.primaryAction.opacity(0.88)
        }

        return canSend ? AppTheme.primaryAction : AppTheme.foreground.opacity(0.12)
    }

    private var buttonForeground: Color {
        if isResponseActive {
            return AppTheme.primaryActionText
        }

        return canSend ? AppTheme.primaryActionText : AppTheme.foreground.opacity(0.4)
    }

    private var statusText: String {
        if isThinking {
            return "Thinking locally on device."
        }

        if isGenerating {
            return "Generating locally on device."
        }

        if generationMetrics.hasValue {
            let latencyText = generationMetrics.firstTokenLatency.map { String(format: "%.1fs first", $0) } ?? "first token n/a"
            return String(
                format: "Last response: ~%d tokens · %.1f tok/s · %@.",
                generationMetrics.outputEstimatedTokens,
                generationMetrics.tokensPerSecond,
                latencyText
            )
        }

        return "On-device responses may take a moment."
    }

    private var inputBox: some View {
        ZStack(alignment: .leading) {
            if prompt.isEmpty {
                Text("Message")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppTheme.foreground.opacity(0.42))
                    .allowsHitTesting(false)
            }

            ComposerTextView(
                text: $prompt,
                isFocused: $isFocused,
                measuredHeight: $inputHeight,
                isEnabled: !isThinking,
                onSubmit: send
            )
            .frame(height: inputHeight)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.subtleFill)
                .stroke(AppTheme.panelStroke, lineWidth: 1)
        )
    }
}
