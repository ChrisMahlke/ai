//
//  ChatViewModel+Generation.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

@MainActor
extension ChatViewModel {
    func useSuggestedPrompt(_ text: String) {
        guard !isResponseActive else { return }

        AppHaptics.selection()
        prompt = text
        isComposerFocused = true
    }

    func sendCurrentPrompt() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, !isResponseActive else { return }
        guard !isInGenerationBackoff else {
            backendNotice = generationBackoffMessage()
            isComposerFocused = true
            return
        }

        AppHaptics.lightImpact()
        isComposerFocused = false
        messages.append(ChatMessage(role: .user, text: trimmedPrompt))
        trimVisibleMessagesIfNeeded()
        prompt = ""
        scheduleHistorySave()

        startResponse(for: trimmedPrompt, history: messages)
    }

    func regenerateLastResponse() {
        guard canRegenerate, let lastUserIndex = messages.lastIndex(where: { $0.role == .user }) else { return }
        guard !isInGenerationBackoff else {
            backendNotice = generationBackoffMessage()
            isComposerFocused = true
            return
        }

        AppHaptics.lightImpact()
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
        cancelGenerationTimeout()
        localAIManager?.cancelGeneration()
        generationTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: self?.generationTimeoutNanoseconds ?? 120_000_000_000)
            guard !Task.isCancelled else { return }

            self?.recoverTimedOutGeneration(chatID: chatID)
        }
        responseTask = Task { [weak self, responder] in
            guard let self else { return }

            let events = await self.generationCoordinator.events(
                prompt: prompt,
                history: history,
                responder: responder
            )

            for await event in events {
                guard !Task.isCancelled else { return }

                switch event {
                case .started(let assistantID):
                    self.beginAssistantResponse(id: assistantID, chatID: chatID)
                case .token(let token, let assistantID):
                    self.appendAssistantToken(token, messageID: assistantID, chatID: chatID)
                case .finished(let didStart):
                    if didStart {
                        self.finishAssistantResponse(chatID: chatID)
                    } else {
                        self.finishCancelledOrEmptyResponse(chatID: chatID)
                    }
                }
            }
        }
    }

    func stopGeneration(triggerHaptic: Bool = true) {
        let shouldMarkStopped = isResponseActive
        if shouldMarkStopped, triggerHaptic {
            AppHaptics.stop()
        }
        localAIManager?.cancelGeneration()
        responseTask?.cancel()
        responseTask = nil
        cancelGenerationTimeout()
        setRuntimeState(.idle)
        generationStartedAt = nil
        isComposerFocused = true

        if messages.last?.role == .assistant, messages.last?.text.isEmpty == true {
            messages[messages.count - 1].text = "Stopped."
            messages[messages.count - 1].state = .stopped
        } else if shouldMarkStopped, messages.last?.role == .assistant {
            messages[messages.count - 1].state = .stopped
        } else if shouldMarkStopped {
            messages.append(ChatMessage(role: .assistant, text: "Stopped.", state: .stopped))
        }

        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func cancelActiveResponse() {
        stopGeneration(triggerHaptic: false)
    }

    func beginAssistantResponse(id: UUID, chatID: UUID) {
        guard chatID == currentChatID else { return }

        generationStartedAt = Date()
        generationMetrics = generationMetrics.starting(prompt: lastUserPrompt(for: chatID))
        setRuntimeState(.generating)
        messages.append(ChatMessage(id: id, role: .assistant, text: "", state: .streaming))
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func appendAssistantToken(_ token: String, messageID: UUID, chatID: UUID) {
        guard chatID == currentChatID else { return }
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }) else { return }

        messages[messageIndex].text += token
        messages[messageIndex].state = .streaming
        updateGenerationMetrics(token)
        scheduleHistorySave()
    }

    func finishAssistantResponse(chatID: UUID) {
        guard chatID == currentChatID else { return }
        responseTask = nil
        cancelGenerationTimeout()
        resetGenerationTimeoutBackoff()
        setRuntimeState(.idle)
        if messages.last?.role == .assistant, messages.last?.state == .streaming {
            messages[messages.count - 1].state = .complete
        }
        localAIManager?.recordInference(metrics: generationMetrics, didFail: false)
        generationStartedAt = nil
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func finishCancelledOrEmptyResponse(chatID: UUID) {
        guard chatID == currentChatID else { return }
        responseTask = nil
        cancelGenerationTimeout()
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

    func cancelGenerationTimeout() {
        generationTimeoutTask?.cancel()
        generationTimeoutTask = nil
    }

    func recoverTimedOutGeneration(chatID: UUID) {
        guard chatID == currentChatID, isResponseActive else { return }

        localAIManager?.cancelGeneration()
        responseTask?.cancel()
        responseTask = nil
        generationTimeoutTask = nil
        generationStartedAt = nil
        applyGenerationTimeoutBackoff()
        setRuntimeState(.idle)
        isComposerFocused = true

        if messages.last?.role == .assistant {
            if messages[messages.count - 1].text.isEmpty {
                messages[messages.count - 1].text = "Generation timed out."
            } else {
                messages[messages.count - 1].text += "\n\nGeneration timed out before the response completed."
            }
            messages[messages.count - 1].state = .failed
        } else {
            messages.append(ChatMessage(role: .assistant, text: "Generation timed out.", state: .failed))
        }

        localAIManager?.recordInference(metrics: generationMetrics, didFail: true)
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func applyGenerationTimeoutBackoff() {
        consecutiveGenerationTimeouts += 1
        let seconds = min(60, 10 * (1 << min(consecutiveGenerationTimeouts - 1, 3)))
        let backoffUntil = Date().addingTimeInterval(TimeInterval(seconds))
        generationBackoffUntil = backoffUntil
        let message = generationBackoffMessage()
        backendNotice = message

        if consecutiveGenerationTimeouts >= 2 {
            localAIManager?.unloadModel(
                reason: "Unloaded local model after repeated generation timeouts.",
                finalState: .unavailable(message)
            )
        }

        generationBackoffTask?.cancel()
        generationBackoffTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            guard !Task.isCancelled else { return }

            self?.generationBackoffUntil = nil
            if self?.backendNotice?.hasPrefix("Generation timed out. Local inference is cooling down") == true {
                self?.backendNotice = nil
            }
        }
    }

    func resetGenerationTimeoutBackoff() {
        consecutiveGenerationTimeouts = 0
        generationBackoffUntil = nil
        generationBackoffTask?.cancel()
        generationBackoffTask = nil
    }

    func generationBackoffMessage() -> String {
        guard let generationBackoffUntil else {
            return "Generation timed out. Try a shorter prompt or Efficient settings."
        }

        let remainingSeconds = max(1, Int(ceil(generationBackoffUntil.timeIntervalSinceNow)))
        return "Generation timed out. Local inference is cooling down for \(remainingSeconds)s. Try a shorter prompt or Efficient settings."
    }
}
