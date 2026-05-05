//
//  SideMenuView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI
import UIKit

struct SideMenuView: View {
    let recentChats: [ChatSession]
    let onNewChat: () -> Void
    let onSavedPrompts: () -> Void
    let onSelectChat: (ChatSession) -> Void
    let onTogglePin: (ChatSession) -> Void
    let onDeleteChat: (ChatSession) -> Void
    let close: () -> Void

    @State private var searchText = ""

    private var filteredChats: [ChatSession] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return recentChats }

        return recentChats.filter { chat in
            chat.title.localizedCaseInsensitiveContains(query)
            || chat.messages.contains { $0.text.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            menuButton(title: "New chat", icon: "square.and.pencil", action: onNewChat)
                .padding(.horizontal, 10)

            menuButton(title: "Saved prompts", icon: "bookmark", action: onSavedPrompts)
                .padding(.horizontal, 10)
                .padding(.top, 4)

            searchField
                .padding(.horizontal, 18)
                .padding(.top, 12)

            Spacer(minLength: 18)

            recentChatsSection
        }
        .frame(maxHeight: .infinity)
        .background(
            AppTheme.drawerBackground
                .ignoresSafeArea()
        )
    }

    private var header: some View {
        HStack {
            Text("ai")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .textCase(.lowercase)

            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close menu")
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 18)
    }

    private var recentChatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent chats")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.42))
                    .textCase(.uppercase)

                Spacer()

                if !recentChats.isEmpty {
                    Text("\(recentChats.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.32))
                }
            }
            .padding(.horizontal, 18)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if filteredChats.isEmpty {
                        Text(recentChats.isEmpty ? "No recent chats" : "No matches")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.36))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(filteredChats) { chat in
                            recentChatButton(chat)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 18)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.34))

            TextField("Search", text: $searchText)
                .font(.system(size: 14, weight: .regular))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.34))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .foregroundStyle(.white.opacity(0.82))
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.065))
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func menuButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 22)

                Text(title)
                    .font(.system(size: 15, weight: .regular))

                Spacer()
            }
            .foregroundStyle(.white.opacity(0.86))
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0))
            )
        }
        .buttonStyle(.plain)
    }

    private func recentChatButton(_ chat: ChatSession) -> some View {
        HStack(spacing: 0) {
            Button {
                onSelectChat(chat)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "message")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(chat.isPinned ? .white.opacity(0.78) : .white.opacity(0.5))
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(chat.title)
                                .font(.system(size: 14, weight: .regular))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        } else {
                            Text(highlighted(chat.title))
                                .font(.system(size: 14, weight: .regular))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        if let snippet = matchingSnippet(for: chat) {
                            Text(highlighted(snippet))
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(.white.opacity(0.38))
                                .lineLimit(1)
                        } else {
                            Text(chat.updatedAt, style: .relative)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(.white.opacity(0.34))
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }
                .foregroundStyle(.white.opacity(0.78))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(chat.isPinned ? "Pinned chat, \(chat.title)" : "Chat, \(chat.title)")

            Button {
                onTogglePin(chat)
            } label: {
                Image(systemName: chat.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(chat.isPinned ? .white.opacity(0.68) : .white.opacity(0.32))
                    .frame(width: 32, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(chat.isPinned ? "Unpin chat" : "Pin chat")

            Button {
                onDeleteChat(chat)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.38))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete chat")
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
        .contextMenu {
            Button {
                onTogglePin(chat)
            } label: {
                Label(chat.isPinned ? "Unpin" : "Pin", systemImage: chat.isPinned ? "pin.slash" : "pin")
            }

            Button(role: .destructive) {
                onDeleteChat(chat)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func matchingSnippet(for chat: ChatSession) -> String? {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        guard let message = chat.messages.first(where: { $0.text.localizedCaseInsensitiveContains(query) }) else {
            return nil
        }

        let collapsed = message.text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !collapsed.isEmpty else { return nil }

        return String(collapsed.prefix(88))
    }

    private func highlighted(_ value: String) -> AttributedString {
        let attributed = NSMutableAttributedString(string: value)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return AttributedString(attributed) }

        let nsValue = value as NSString
        var searchRange = NSRange(location: 0, length: nsValue.length)

        while searchRange.location < nsValue.length {
            let foundRange = nsValue.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchRange
            )
            guard foundRange.location != NSNotFound else { break }

            attributed.addAttribute(.backgroundColor, value: UIColor.white.withAlphaComponent(0.18), range: foundRange)
            let nextLocation = foundRange.location + max(foundRange.length, 1)
            searchRange = NSRange(location: nextLocation, length: nsValue.length - nextLocation)
        }

        return AttributedString(attributed)
    }
}
