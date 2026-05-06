//
//  ChatHeaderView.swift
//  falken
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
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open menu")
            .accessibilityHint("Shows or hides the chat menu")

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(AppTheme.foreground.opacity(0.86))

            Spacer()

            Button(action: startNewChat) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start new chat")
            .accessibilityHint("Saves the current chat if needed and opens an empty chat")

            Button(action: shareChat) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share chat")
            .accessibilityHint("Opens the iOS share sheet for this chat transcript")

            Button(action: toggleOverflow) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options")
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(AppTheme.background)
    }
}
