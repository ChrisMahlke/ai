//
//  ThinkingIndicatorView.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ThinkingIndicatorView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AppTheme.foreground.opacity(0.74))
                    .frame(width: 7, height: 7)
                    .scaleEffect(isAnimating ? 1.0 : 0.58)
                    .opacity(isAnimating ? 0.92 : 0.32)
                    .animation(
                        .easeInOut(duration: 0.62)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.14),
                        value: isAnimating
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.foreground.opacity(0.075))
                .stroke(AppTheme.foreground.opacity(0.11), lineWidth: 1)
        )
        .onAppear {
            isAnimating = true
        }
        .accessibilityLabel("Thinking")
    }
}
