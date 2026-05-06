//
//  ChatProviderStore.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

nonisolated struct ChatProviderStore {
    private let defaults: UserDefaults
    private let key = "chatProvider.v1"

    nonisolated init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    nonisolated func load() -> ChatProvider {
        guard
            let rawValue = defaults.string(forKey: key),
            let provider = ChatProvider(rawValue: rawValue)
        else {
            return .local
        }

        return provider
    }

    nonisolated func save(_ provider: ChatProvider) {
        defaults.set(provider.rawValue, forKey: key)
    }
}
