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
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
                .textSelection(.enabled)
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = message.text
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }

            if !isUser {
                Spacer(minLength: 44)
            }
        }
    }
}
