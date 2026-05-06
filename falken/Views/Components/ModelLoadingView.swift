//
//  ModelLoadingView.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ModelLoadingView: View {
    let progress: Double
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.foreground.opacity(0.66))
                    .lineLimit(1)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.foreground.opacity(0.42))
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(AppTheme.foreground.opacity(0.82))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(AppTheme.background)
    }
}
