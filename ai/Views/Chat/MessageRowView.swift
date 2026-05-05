//
//  MessageRowView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI
import UIKit

struct MessageRowView: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .top) {
            if isUser {
                Spacer(minLength: 44)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 7) {
                Text(message.text)
                    .font(.system(size: 16, weight: .regular))
                    .lineSpacing(4)
                    .foregroundStyle(isUser ? .black : .white.opacity(0.9))
                    .padding(.horizontal, isUser ? 15 : 0)
                    .padding(.vertical, isUser ? 12 : 0)
                    .background {
                        if isUser {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                        }
                    }
                    .textSelection(.enabled)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.text
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }

                if message.state == .stopped {
                    stateBadge("Stopped", foreground: .white.opacity(0.42), background: .white.opacity(0.055))
                } else if message.state == .failed {
                    stateBadge("Failed", foreground: .red.opacity(0.78), background: .red.opacity(0.1))
                }
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

            if !isUser {
                Spacer(minLength: 44)
            }
        }
    }

    private func stateBadge(_ title: String, foreground: Color, background: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(background)
            )
    }
}
