//
//  LocalModelChatResponder.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelChatResponder: ChatResponding {
    let configuration: InferenceConfiguration
    let manager: LocalAIManager

    init(
        configuration: InferenceConfiguration = .default,
        manager: LocalAIManager
    ) {
        self.configuration = configuration
        self.manager = manager
    }

    func responseStream(for prompt: String, history: [ChatMessage]) async -> AsyncStream<String> {
        await manager.loadModelIfNeeded()
        return manager.generateResponse(prompt: prompt, history: history)
    }
}
