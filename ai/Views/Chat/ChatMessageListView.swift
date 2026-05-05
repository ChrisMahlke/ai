//
//  ChatMessageListView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ChatMessageListView: View {
    let messages: [ChatMessage]
    let isThinking: Bool
    let searchQuery: String
    let useSuggestion: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    if messages.isEmpty {
                        EmptyChatView(useSuggestion: useSuggestion)
                    }

                    ForEach(messages) { message in
                        MessageRowView(message: message, searchQuery: searchQuery)
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
        }
    }

    private func scrollToBottom(with proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}
