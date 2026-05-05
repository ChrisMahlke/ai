//
//  GeminiChatResponder.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct GeminiChatResponder: ChatResponding {
    let configuration: InferenceConfiguration

    func responseStream(for prompt: String, history: [ChatMessage]) async -> AsyncStream<String> {
        // Future integration point for Gemini SDK calls when the user opts into
        // remote inference instead of the default local open-weight model path.
        await PlaceholderChatResponder(configuration: configuration)
            .responseStream(for: prompt, history: history)
    }
}
