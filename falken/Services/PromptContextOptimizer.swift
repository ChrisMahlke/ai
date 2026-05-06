//
//  PromptContextOptimizer.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

struct PromptContextOptimizer {
    let tokenBudget: Int
    let reservedResponseTokens: Int

    init(tokenBudget: Int, reservedResponseTokens: Int) {
        self.tokenBudget = max(tokenBudget, 512)
        self.reservedResponseTokens = max(reservedResponseTokens, 64)
    }

    func optimizedMessages(from history: [ChatMessage]) -> [ChatMessage] {
        let usableBudget = max(256, tokenBudget - reservedResponseTokens - 128)
        var selected: [ChatMessage] = []
        var selectedTokens = 0
        var overflow: [ChatMessage] = []

        for message in history.reversed() {
            let estimatedTokens = GenerationMetrics.estimateTokens(in: message.text) + 6
            if selectedTokens + estimatedTokens <= usableBudget || selected.isEmpty {
                selected.insert(message, at: 0)
                selectedTokens += estimatedTokens
            } else {
                overflow.insert(message, at: 0)
            }
        }

        guard !overflow.isEmpty else { return selected }

        let summary = summarize(overflow)
        guard !summary.isEmpty else { return selected }

        return [ChatMessage(role: .assistant, text: "Earlier conversation summary: \(summary)")] + selected
    }

    private func summarize(_ messages: [ChatMessage]) -> String {
        let snippets = messages
            .suffix(8)
            .map { message in
                let speaker = message.role == .user ? "User" : "Assistant"
                let compactText = message.text
                    .replacingOccurrences(of: "\n", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return "\(speaker): \(compactText.prefix(160))"
            }

        return snippets.joined(separator: " | ")
    }
}
