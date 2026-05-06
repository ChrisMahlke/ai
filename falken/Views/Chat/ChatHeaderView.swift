//
//  ChatHeaderView.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ChatHeaderView: View {
    let title: String
    let providerStatus: ProviderStatus
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

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(AppTheme.foreground.opacity(0.86))

                ModelStatusChip(status: providerStatus)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

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

private struct ModelStatusChip: View {
    let status: ProviderStatus

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.foreground.opacity(0.58))
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .frame(height: 19)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.panelFill)
                .stroke(AppTheme.panelStroke.opacity(0.8), lineWidth: 1)
        )
        .accessibilityLabel("Model status: \(label)")
    }

    private var label: String {
        switch status.health {
        case .ready:
            return "Ready"
        case .loading:
            return "Loading"
        case .unavailable, .notConfigured:
            return "Needs model"
        case .unknown:
            return "Local"
        }
    }

    private var indicatorColor: Color {
        switch status.health {
        case .ready:
            return .green.opacity(0.78)
        case .loading:
            return .yellow.opacity(0.84)
        case .unavailable, .notConfigured:
            return .red.opacity(0.72)
        case .unknown:
            return AppTheme.foreground.opacity(0.36)
        }
    }
}
