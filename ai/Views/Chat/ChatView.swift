//
//  ChatView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        ZStack(alignment: .leading) {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ChatHeaderView(
                    title: viewModel.chatTitle,
                    openMenu: viewModel.openDrawer,
                    startNewChat: viewModel.startNewChat,
                    shareChat: viewModel.shareCurrentChat,
                    toggleOverflow: viewModel.toggleOverflowMenu
                )

                if viewModel.isModelLoading {
                    ModelLoadingView(
                        progress: viewModel.modelLoadProgress,
                        message: viewModel.modelLoadMessage
                    )
                }

                if let backendNotice = viewModel.backendNotice {
                    ModelStatusBannerView(
                        message: backendNotice,
                        retry: viewModel.retryLocalModelLoad,
                        useEfficient: viewModel.useEfficientModelSettings,
                        openSettings: viewModel.openModelSettings
                    )
                }

                if !viewModel.messages.isEmpty {
                    ChatSearchBarView(
                        query: $viewModel.chatSearchQuery,
                        matchCount: viewModel.chatSearchMatchCount
                    )
                }

                ChatMessageListView(
                    messages: viewModel.messages,
                    isThinking: viewModel.isThinking,
                    searchQuery: viewModel.chatSearchQuery,
                    useSuggestion: viewModel.useSuggestedPrompt
                )

                ChatComposerView(
                    prompt: $viewModel.prompt,
                    isFocused: $viewModel.isComposerFocused,
                    inputHeight: $viewModel.composerInputHeight,
                    canSend: viewModel.canSend,
                    isThinking: viewModel.isThinking,
                    isGenerating: viewModel.isGenerating,
                    isResponseActive: viewModel.isResponseActive,
                    generationMetrics: viewModel.generationMetrics,
                    canRegenerate: viewModel.canRegenerate,
                    send: viewModel.sendCurrentPrompt,
                    stop: viewModel.stopGeneration,
                    regenerate: viewModel.regenerateLastResponse
                )
            }
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)

            if viewModel.isOverflowOpen {
                OverflowOverlay(
                    close: viewModel.closeOverflowMenu,
                    select: viewModel.selectOverflowItem
                )
            }

            if viewModel.isDrawerOpen {
                DrawerOverlay(
                    recentChats: viewModel.recentChats,
                    startNewChat: viewModel.startNewChat,
                    selectChat: viewModel.loadChat,
                    deleteChat: viewModel.deleteRecentChat,
                    close: viewModel.closeDrawer
                )
            }
        }
        .foregroundStyle(.white)
        .task {
            await viewModel.loadBackendIfNeeded()
        }
        .onDisappear {
            viewModel.cancelActiveResponse()
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: viewModel.isDrawerOpen)
        .fullScreenCover(item: $viewModel.presentedOverflowItem) { item in
            OverflowModalView(
                item: item,
                currentChatTitle: viewModel.chatTitle,
                hasArchivableChat: viewModel.hasArchivableChat,
                modelSettings: viewModel.modelSettings,
                modelDiagnostics: viewModel.modelDiagnostics,
                selectedProvider: viewModel.selectedProvider,
                providerStatus: viewModel.providerStatus,
                close: viewModel.dismissOverflowModal,
                renameChat: viewModel.renameCurrentChat,
                archiveChat: viewModel.archiveCurrentChatAndStartNew,
                saveModelSettings: viewModel.updateModelSettings,
                selectProvider: viewModel.selectProvider,
                validateModelSettings: viewModel.validateModelSettings,
                testModelSettings: viewModel.testModelSettings,
                clearChatHistory: viewModel.clearChatHistory
            )
        }
        .sheet(item: $viewModel.sharePayload) { payload in
            ShareSheet(items: [payload.text])
        }
    }
}

private struct OverflowOverlay: View {
    let close: () -> Void
    let select: (OverflowMenuItem) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture(perform: close)

            OverflowMenuView(select: select)
                .padding(.top, 56)
                .padding(.trailing, 12)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .zIndex(4)
    }
}

private struct DrawerOverlay: View {
    let recentChats: [ChatSession]
    let startNewChat: () -> Void
    let selectChat: (ChatSession) -> Void
    let deleteChat: (ChatSession) -> Void
    let close: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.44)
                .ignoresSafeArea()
                .onTapGesture(perform: close)

            SideMenuView(
                recentChats: recentChats,
                onNewChat: startNewChat,
                onSelectChat: selectChat,
                onDeleteChat: deleteChat,
                close: close
            )
            .frame(width: 304)
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
        .zIndex(2)
    }
}
