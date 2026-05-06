//
//  ChatViewModel+Navigation.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

@MainActor
extension ChatViewModel {
    func openModelSettings() {
        AppHaptics.selection()
        isOverflowOpen = false
        isComposerFocused = false
        presentedOverflowItem = .settings
    }

    func openModelDiagnostics() {
        AppHaptics.selection()
        isOverflowOpen = false
        isComposerFocused = false
        presentedOverflowItem = .diagnostics
    }

    func openDrawer() {
        AppHaptics.selection()
        isComposerFocused = false
        isDrawerOpen = true
    }

    func closeDrawer() {
        AppHaptics.selection()
        isDrawerOpen = false
    }

    func togglePersistentSidebar() {
        AppHaptics.selection()
        isSidebarCollapsed.toggle()
    }

    func toggleOverflowMenu() {
        AppHaptics.selection()
        isComposerFocused = false
        isOverflowOpen.toggle()
    }

    func closeOverflowMenu() {
        isOverflowOpen = false
    }

    func selectOverflowItem(_ item: OverflowMenuItem) {
        AppHaptics.selection()
        isOverflowOpen = false
        isComposerFocused = false
        presentedOverflowItem = item
    }

    func dismissOverflowModal() {
        presentedOverflowItem = nil
    }

    func openPromptLibrary() {
        AppHaptics.selection()
        isComposerFocused = false
        isDrawerOpen = false
        isPromptLibraryPresented = true
    }

    func dismissPromptLibrary() {
        isPromptLibraryPresented = false
    }

    func usePromptTemplate(_ template: PromptTemplate) {
        guard !isResponseActive else { return }

        prompt = template.text
        isPromptLibraryPresented = false
        isComposerFocused = true
        AppHaptics.selection()
    }

    func savePromptTemplate(title: String, text: String) {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty, !normalizedText.isEmpty else { return }

        let template = PromptTemplate(
            title: String(normalizedTitle.prefix(64)),
            text: String(normalizedText.prefix(2_000)),
            category: "Saved"
        )
        promptTemplates.insert(template, at: PromptTemplate.builtIns.count)
        promptTemplateStore.save(promptTemplates)
    }

    func deletePromptTemplate(_ template: PromptTemplate) {
        guard !template.isBuiltIn else { return }

        promptTemplates.removeAll { $0.id == template.id }
        promptTemplateStore.save(promptTemplates)
    }

    func shareCurrentChat() {
        let transcript = transcriptText()
        guard !transcript.isEmpty else { return }

        AppHaptics.selection()
        isComposerFocused = false
        sharePayload = SharePayload(text: transcript)
    }

    func resetChatSearchNavigation() {
        chatSearchActiveMessageID = chatSearchResultMessageIDs.first
    }

    func updateChatSearchQuery(_ query: String) {
        chatSearchQuery = query
        Task { @MainActor [weak self] in
            await Task.yield()
            guard let self, self.chatSearchQuery == query else { return }

            self.chatSearchActiveMessageID = self.chatSearchResultMessageIDs.first
        }
    }

    func jumpToNextSearchResult() {
        jumpSearchResult(direction: 1)
    }

    func jumpToPreviousSearchResult() {
        jumpSearchResult(direction: -1)
    }

    private func jumpSearchResult(direction: Int) {
        let ids = chatSearchResultMessageIDs
        guard !ids.isEmpty else {
            chatSearchActiveMessageID = nil
            return
        }

        let currentIndex = chatSearchActiveMessageID.flatMap { ids.firstIndex(of: $0) } ?? 0
        let nextIndex = (currentIndex + direction + ids.count) % ids.count
        chatSearchActiveMessageID = ids[nextIndex]
        AppHaptics.selection()
    }
}
