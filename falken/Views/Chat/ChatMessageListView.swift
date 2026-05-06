//
//  ChatMessageListView.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI
import UIKit

struct ChatMessageListView: View {
    let messages: [ChatMessage]
    let isThinking: Bool
    let searchQuery: String
    let activeSearchMessageID: UUID?
    let useSuggestion: (String) -> Void
    let editMessage: (ChatMessage) -> Void
    let deleteMessage: (ChatMessage) -> Void
    let continueFromMessage: (ChatMessage) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    if messages.isEmpty {
                        EmptyChatView(useSuggestion: useSuggestion)
                    }

                    ForEach(messages) { message in
                        MessageRowView(
                            message: message,
                            searchQuery: searchQuery,
                            isActiveSearchResult: message.id == activeSearchMessageID,
                            canContinueFromHere: message.id != messages.last?.id,
                            editMessage: editMessage,
                            deleteMessage: deleteMessage,
                            continueFromMessage: continueFromMessage
                        )
                            .id(message.id)
                    }

                    if isThinking {
                        ThinkingIndicatorView()
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 18)
            }
            .scrollIndicators(.hidden)
            .onChange(of: messages) { _, newValue in
                guard !newValue.isEmpty else { return }
                scrollToBottom(with: proxy)
            }
            .onChange(of: isThinking) { _, _ in
                scrollToBottom(with: proxy)
            }
            .onChange(of: activeSearchMessageID) { _, messageID in
                guard let messageID else { return }

                withAnimation(.easeOut(duration: UIAccessibility.isReduceMotionEnabled ? 0.01 : 0.2)) {
                    proxy.scrollTo(messageID, anchor: .center)
                }
            }
        }
    }

    private func scrollToBottom(with proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: UIAccessibility.isReduceMotionEnabled ? 0.01 : 0.25)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}
