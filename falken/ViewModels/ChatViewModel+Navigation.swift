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
        isOverflowOpen = false
        isComposerFocused = false
        presentedOverflowItem = .settings
    }

    func openDrawer() {
        isComposerFocused = false
        isDrawerOpen = true
    }

    func closeDrawer() {
        isDrawerOpen = false
    }

    func togglePersistentSidebar() {
        isSidebarCollapsed.toggle()
    }

    func toggleOverflowMenu() {
        isComposerFocused = false
        isOverflowOpen.toggle()
    }

    func closeOverflowMenu() {
        isOverflowOpen = false
    }

    func selectOverflowItem(_ item: OverflowMenuItem) {
        isOverflowOpen = false
        isComposerFocused = false
        presentedOverflowItem = item
    }

    func dismissOverflowModal() {
        presentedOverflowItem = nil
    }

    func openPromptLibrary() {
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

        isComposerFocused = false
        sharePayload = SharePayload(text: transcript)
    }
}
