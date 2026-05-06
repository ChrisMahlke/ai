//
//  OverflowModalHelpContent.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct HelpSummaryPanel: View {
    var body: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("What this app is")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.foreground.opacity(0.92))

                Text("A minimal chat app built around local-first AI. The default path runs an open-weight model inside the app process so the phone can answer without a server request. The architecture also supports an optional Gemini provider when a cloud model is selected.")
                    .font(.system(size: 15, weight: .regular))
                    .lineSpacing(4)
                    .foregroundStyle(AppTheme.foreground.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    HelpBadge(text: "Local-first")
                    HelpBadge(text: "Streaming")
                    HelpBadge(text: "Memory-aware")
                }
            }
        }
    }
}

struct HelpRequestFlowPanel: View {
    private let steps = [
        (
            title: "Prompt",
            text: "Your message is combined with the current chat context and a system instruction that defines assistant behavior."
        ),
        (
            title: "Provider",
            text: "The app chooses the active provider: the local model by default, or Gemini if you selected the cloud path in Settings."
        ),
        (
            title: "Inference",
            text: "For local AI, the bundled model reads tokens from the prompt and predicts the next tokens until the response is complete or stopped."
        ),
        (
            title: "Streaming",
            text: "Generated text is shown as it arrives, so the conversation feels responsive even while the model is still working."
        )
    ]

    var body: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("How a message works")

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HelpStepRow(number: index + 1, title: step.title, text: step.text)
                    }
                }
            }
        }
    }
}

struct HelpDefinitionPanel: View {
    private let definitions = [
        (
            term: "Local model",
            definition: "An AI model file bundled with the app and executed on the iPhone or iPad."
        ),
        (
            term: "Open-weight",
            definition: "A model whose weights are available for local use under its license. Gemma is the current target family."
        ),
        (
            term: "GGUF",
            definition: "The model file format used by the local runtime. It packages weights and metadata for efficient loading."
        ),
        (
            term: "Quantization",
            definition: "A compression technique that stores model weights with fewer bits. It lowers RAM and storage use, usually with some quality tradeoff."
        ),
        (
            term: "Token",
            definition: "A small piece of text the model reads or writes. Tokens are not always whole words."
        ),
        (
            term: "Context",
            definition: "The prompt plus recent conversation history that the model can see while answering."
        ),
        (
            term: "Preset",
            definition: "A group of generation settings such as speed, token limit, and creativity that balances quality against device load."
        )
    ]

    var body: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Definitions")

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(definitions, id: \.term) { item in
                        HelpDefinitionRow(term: item.term, definition: item.definition)
                    }
                }
            }
        }
    }
}

struct HelpPanel: View {
    let title: String
    let text: String

    var body: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.foreground.opacity(0.9))

                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .lineSpacing(4)
                    .foregroundStyle(AppTheme.foreground.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct HelpTroubleshootingPanel: View {
    private let items = [
        (
            title: "Model missing",
            text: "Open Models and confirm the selected profile is installed. If it is unavailable, add the GGUF file to ai/Models, include it in the app target, and rebuild."
        ),
        (
            title: "Slow responses",
            text: "Use the smaller model profile, switch to Efficient, reduce max tokens, or wait for the device to cool down."
        ),
        (
            title: "Short or repetitive answers",
            text: "Try Balanced or Quality, increase the token limit, or start a new chat so less old context competes with the current request."
        ),
        (
            title: "Unexpected cloud use",
            text: "Open Settings and verify the provider is Local. Gemini is only used when the Gemini provider is selected."
        )
    ]

    var body: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Troubleshooting")

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(items, id: \.title) { item in
                        HelpDefinitionRow(term: item.title, definition: item.text)
                    }
                }
            }
        }
    }
}

private struct HelpStepRow: View {
    let number: Int
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryActionText.opacity(0.74))
                .frame(width: 24, height: 24)
                .background(AppTheme.primaryAction.opacity(0.86))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.foreground.opacity(0.88))

                Text(text)
                    .font(.system(size: 13, weight: .regular))
                    .lineSpacing(3)
                    .foregroundStyle(AppTheme.foreground.opacity(0.52))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct HelpDefinitionRow: View {
    let term: String
    let definition: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(term)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.foreground.opacity(0.84))

            Text(definition)
                .font(.system(size: 13, weight: .regular))
                .lineSpacing(3)
                .foregroundStyle(AppTheme.foreground.opacity(0.52))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct HelpBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.foreground.opacity(0.76))
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(AppTheme.subtleFill)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
