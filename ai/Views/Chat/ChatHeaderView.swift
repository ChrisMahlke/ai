//
//  ChatHeaderView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ChatHeaderView: View {
    let title: String
    let openMenu: () -> Void
    let startNewChat: () -> Void
    let shareChat: () -> Void
    let toggleOverflow: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: openMenu) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open menu")

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.white.opacity(0.86))

            Spacer()

            Button(action: startNewChat) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 34, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start new chat")

            Button(action: shareChat) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 34, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share chat")

            Button(action: toggleOverflow) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 34, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options")
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(AppTheme.background)
    }
}
