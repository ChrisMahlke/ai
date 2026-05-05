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
    let send: () -> Void
    let stop: () -> Void

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
            }

            Text(statusText)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.38))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .background(
            Rectangle()
                .fill(AppTheme.background)
                .shadow(color: .black.opacity(0.28), radius: 16, y: -8)
        )
    }

    private var buttonBackground: Color {
        if isResponseActive {
            return Color.white.opacity(0.88)
        }

        return canSend ? Color.white : Color.white.opacity(0.12)
    }

    private var buttonForeground: Color {
        if isResponseActive {
            return Color.black
        }

        return canSend ? Color.black : Color.white.opacity(0.4)
    }

    private var statusText: String {
        if isThinking {
            return "Thinking locally on device."
        }

        if isGenerating {
            return "Generating locally on device."
        }

        if generationMetrics.hasValue {
            return String(
                format: "Last response: %d chunks · %.1f chunks/s.",
                generationMetrics.tokenChunks,
                generationMetrics.chunksPerSecond
            )
        }

        return "On-device responses may take a moment."
    }

    private var inputBox: some View {
        ZStack(alignment: .leading) {
            if prompt.isEmpty {
                Text("Message")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.38))
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
                .fill(Color.white.opacity(0.075))
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}
