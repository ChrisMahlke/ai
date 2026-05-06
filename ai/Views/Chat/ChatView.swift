//
//  ChatView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .leading) {
            AppTheme.background
                .ignoresSafeArea()

            HStack(spacing: 0) {
                if usesPersistentSidebar, !viewModel.isSidebarCollapsed {
                    SideMenuView(
                        recentChats: viewModel.recentChats,
                        onNewChat: viewModel.startNewChat,
                        onSavedPrompts: viewModel.openPromptLibrary,
                        onSelectChat: viewModel.loadChat,
                        onTogglePin: viewModel.togglePinnedRecentChat,
                        onDeleteChat: viewModel.deleteRecentChat,
                        close: viewModel.togglePersistentSidebar
                    )
                    .frame(width: 304)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                chatSurface
                    .frame(maxWidth: usesPersistentSidebar ? .infinity : 820)
                    .frame(maxWidth: .infinity)
            }

            if viewModel.isOverflowOpen {
                OverflowOverlay(
                    close: viewModel.closeOverflowMenu,
                    select: viewModel.selectOverflowItem
                )
            }

            if !usesPersistentSidebar, viewModel.isDrawerOpen {
                DrawerOverlay(
                    recentChats: viewModel.recentChats,
                    startNewChat: viewModel.startNewChat,
                    openPromptLibrary: viewModel.openPromptLibrary,
                    selectChat: viewModel.loadChat,
                    togglePin: viewModel.togglePinnedRecentChat,
                    deleteChat: viewModel.deleteRecentChat,
                    close: viewModel.closeDrawer
                )
            }
        }
        .foregroundStyle(AppTheme.foreground)
        .task {
            await viewModel.loadBackendIfNeeded()
        }
        .onDisappear {
            viewModel.cancelActiveResponse()
        }
        .animation(.spring(response: reduceMotion ? 0.01 : 0.34, dampingFraction: 0.86), value: viewModel.isDrawerOpen)
        .animation(.spring(response: reduceMotion ? 0.01 : 0.34, dampingFraction: 0.86), value: viewModel.isSidebarCollapsed)
        .fullScreenCover(item: $viewModel.presentedOverflowItem) { item in
            OverflowModalView(
                item: item,
                currentChatTitle: viewModel.chatTitle,
                hasArchivableChat: viewModel.hasArchivableChat,
                modelSettings: viewModel.modelSettings,
                modelDiagnostics: viewModel.modelDiagnostics,
                selectedProvider: viewModel.selectedProvider,
                providerStatus: viewModel.providerStatus,
                activeModelProfile: viewModel.activeModelProfile,
                installedModels: viewModel.installedModels,
                appearanceMode: viewModel.appearanceMode,
                diagnosticsReport: viewModel.anonymizedDiagnosticsReport,
                close: viewModel.dismissOverflowModal,
                renameChat: viewModel.renameCurrentChat,
                archiveChat: viewModel.archiveCurrentChatAndStartNew,
                saveModelSettings: viewModel.updateModelSettings,
                selectProvider: viewModel.selectProvider,
                selectModelProfile: viewModel.selectModelProfile,
                updateAppearanceMode: viewModel.updateAppearanceMode,
                validateModelSettings: viewModel.validateModelSettings,
                testModelSettings: viewModel.testModelSettings,
                copyDiagnostics: viewModel.copyDiagnosticsReport,
                clearChatHistory: viewModel.clearChatHistory
            )
        }
        .fullScreenCover(isPresented: $viewModel.isPromptLibraryPresented) {
            PromptLibraryView(
                templates: viewModel.promptTemplates,
                close: viewModel.dismissPromptLibrary,
                select: viewModel.usePromptTemplate,
                save: viewModel.savePromptTemplate,
                delete: viewModel.deletePromptTemplate
            )
            .preferredColorScheme(viewModel.appearanceMode.colorScheme)
        }
        .sheet(item: $viewModel.sharePayload) { payload in
            ShareSheet(items: [payload.text])
        }
        .fullScreenCover(isPresented: $viewModel.isOnboardingPresented) {
            OnboardingView(
                installedModels: viewModel.installedModels,
                complete: viewModel.completeOnboarding
            )
            .preferredColorScheme(viewModel.appearanceMode.colorScheme)
        }
        .preferredColorScheme(viewModel.appearanceMode.colorScheme)
    }

    private var usesPersistentSidebar: Bool {
        horizontalSizeClass == .regular
    }

    private var chatSurface: some View {
        VStack(spacing: 0) {
            ChatHeaderView(
                title: viewModel.chatTitle,
                openMenu: usesPersistentSidebar ? viewModel.togglePersistentSidebar : viewModel.openDrawer,
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
                useSuggestion: viewModel.useSuggestedPrompt,
                editMessage: viewModel.editMessage,
                deleteMessage: viewModel.deleteMessage,
                continueFromMessage: viewModel.continueFromMessage
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
    let openPromptLibrary: () -> Void
    let selectChat: (ChatSession) -> Void
    let togglePin: (ChatSession) -> Void
    let deleteChat: (ChatSession) -> Void
    let close: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            AppTheme.scrim
                .ignoresSafeArea()
                .onTapGesture(perform: close)

            SideMenuView(
                recentChats: recentChats,
                onNewChat: startNewChat,
                onSavedPrompts: openPromptLibrary,
                onSelectChat: selectChat,
                onTogglePin: togglePin,
                onDeleteChat: deleteChat,
                close: close
            )
            .frame(width: 304)
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
        .zIndex(2)
    }
}
