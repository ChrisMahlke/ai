//
//  EmptyChatView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct EmptyChatView: View {
    let useSuggestion: (String) -> Void

    private let suggestions = [
        "Summarize this in three bullets.",
        "Draft a concise reply.",
        "Help me think through a decision."
    ]

    var body: some View {
        VStack(spacing: 18) {
            Text("ai")
                .font(.system(size: 38, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
                .textCase(.lowercase)

            Text("Ask anything.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.44))

            VStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        useSuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.white.opacity(0.055))
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 320)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }
}
