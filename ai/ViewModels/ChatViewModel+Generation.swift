//
//  ChatViewModel+Generation.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

@MainActor
extension ChatViewModel {
    func useSuggestedPrompt(_ text: String) {
        guard !isResponseActive else { return }

        prompt = text
        isComposerFocused = true
    }

    func sendCurrentPrompt() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, !isResponseActive else { return }

        isComposerFocused = false
        messages.append(ChatMessage(role: .user, text: trimmedPrompt))
        trimVisibleMessagesIfNeeded()
        prompt = ""
        scheduleHistorySave()

        startResponse(for: trimmedPrompt, history: messages)
    }

    func regenerateLastResponse() {
        guard canRegenerate, let lastUserIndex = messages.lastIndex(where: { $0.role == .user }) else { return }

        isComposerFocused = false
        let lastPrompt = messages[lastUserIndex].text
        messages = Array(messages.prefix(lastUserIndex + 1))
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()

        startResponse(for: lastPrompt, history: messages)
    }

    func editMessage(_ message: ChatMessage) {
        guard !isResponseActive, message.role == .user,
              let messageIndex = messages.firstIndex(where: { $0.id == message.id })
        else { return }

        prompt = messages[messageIndex].text
        messages = Array(messages.prefix(messageIndex))
        setRuntimeState(.idle)
        generationMetrics = .empty
        isComposerFocused = true
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func deleteMessage(_ message: ChatMessage) {
        guard !isResponseActive else { return }
        messages.removeAll { $0.id == message.id }
        if !messages.contains(where: { $0.role == .user }) {
            currentTitleOverride = nil
        }
        generationMetrics = .empty
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func continueFromMessage(_ message: ChatMessage) {
        guard !isResponseActive,
              let messageIndex = messages.firstIndex(where: { $0.id == message.id })
        else { return }

        messages = Array(messages.prefix(messageIndex + 1))
        generationMetrics = .empty
        isComposerFocused = true
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func startResponse(for prompt: String, history: [ChatMessage]) {
        generationMetrics = GenerationMetrics.empty.starting(prompt: prompt)
        generationStartedAt = nil
        setRuntimeState(.thinking)
        backendNotice = nil

        let chatID = currentChatID
        let responder = activeResponder

        responseTask?.cancel()
        localAIManager?.cancelGeneration()
        responseTask = Task { [weak self, responder] in
            guard let self else { return }

            let stream = await responder.responseStream(for: prompt, history: history)
            let assistantID = UUID()
            var didStartResponse = false

            for await token in stream {
                guard !Task.isCancelled else { return }

                if !didStartResponse {
                    self.beginAssistantResponse(id: assistantID, chatID: chatID)
                    didStartResponse = true
                }

                self.appendAssistantToken(token, messageID: assistantID, chatID: chatID)
            }

            if didStartResponse {
                self.finishAssistantResponse(chatID: chatID)
            } else {
                self.finishCancelledOrEmptyResponse(chatID: chatID)
            }
        }
    }

    func stopGeneration() {
        let shouldMarkStopped = isResponseActive
        localAIManager?.cancelGeneration()
        responseTask?.cancel()
        responseTask = nil
        setRuntimeState(.idle)

        if messages.last?.role == .assistant, messages.last?.text.isEmpty == true {
            messages.removeLast()
        } else if shouldMarkStopped, messages.last?.role == .assistant {
            messages[messages.count - 1].state = .stopped
        }

        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func cancelActiveResponse() {
        stopGeneration()
    }

    func beginAssistantResponse(id: UUID, chatID: UUID) {
        guard chatID == currentChatID else { return }

        generationStartedAt = Date()
        generationMetrics = generationMetrics.starting(prompt: lastUserPrompt(for: chatID))
        setRuntimeState(.generating)
        messages.append(ChatMessage(id: id, role: .assistant, text: ""))
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func appendAssistantToken(_ token: String, messageID: UUID, chatID: UUID) {
        guard chatID == currentChatID else { return }
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }) else { return }

        messages[messageIndex].text += token
        messages[messageIndex].state = .complete
        updateGenerationMetrics(token)
        scheduleHistorySave()
    }

    func finishAssistantResponse(chatID: UUID) {
        guard chatID == currentChatID else { return }
        responseTask = nil
        setRuntimeState(.idle)
        generationStartedAt = nil
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func finishCancelledOrEmptyResponse(chatID: UUID) {
        guard chatID == currentChatID else { return }
        responseTask = nil
        setRuntimeState(.idle)
        generationStartedAt = nil
        scheduleHistorySave()
    }

    func updateGenerationMetrics(_ token: String) {
        guard let generationStartedAt else { return }

        generationMetrics = generationMetrics.addingChunk(
            token,
            elapsedSeconds: Date().timeIntervalSince(generationStartedAt)
        )
    }

    func lastUserPrompt(for chatID: UUID) -> String {
        guard chatID == currentChatID else { return "" }

        return messages.last { $0.role == .user }?.text ?? ""
    }
}
