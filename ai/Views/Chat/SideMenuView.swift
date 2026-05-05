//
//  SideMenuView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct SideMenuView: View {
    let recentChats: [ChatSession]
    let onNewChat: () -> Void
    let onSelectChat: (ChatSession) -> Void
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

            menuButton(title: "Saved prompts", icon: "bookmark", action: close)
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
            .frame(maxHeight: 320)
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
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(chat.title)
                            .font(.system(size: 14, weight: .regular))
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Text(chat.updatedAt, style: .relative)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.34))
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .foregroundStyle(.white.opacity(0.78))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
            Button(role: .destructive) {
                onDeleteChat(chat)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
