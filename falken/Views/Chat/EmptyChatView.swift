//
//  EmptyChatView.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct EmptyChatView: View {
    let useSuggestion: (String) -> Void

    private let suggestions = [
        "Summarize the key points.",
        "Draft a concise reply.",
        "List next actions."
    ]

    var body: some View {
        VStack(spacing: 14) {
            Text(AppBrand.spacedName)
                .font(.system(size: 31, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.foreground.opacity(0.82))
                .textCase(.lowercase)

            Text("Ask anything. Local responses stay on this device when the model is ready.")
                .font(.system(size: 12, weight: .regular))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .foregroundStyle(AppTheme.foreground.opacity(0.44))
                .frame(maxWidth: 340)

            VStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        useSuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(AppTheme.foreground.opacity(0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(AppTheme.foreground.opacity(0.055))
                                    .stroke(AppTheme.foreground.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 284)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 86)
    }
}
