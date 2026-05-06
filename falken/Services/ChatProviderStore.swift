//
//  ChatProviderStore.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct ChatProviderStore {
    private let defaults: UserDefaults
    private let key = "chatProvider.v1"

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func load() -> ChatProvider {
        guard
            let rawValue = defaults.string(forKey: key),
            let provider = ChatProvider(rawValue: rawValue)
        else {
            return .local
        }

        return provider
    }

    func save(_ provider: ChatProvider) {
        defaults.set(provider.rawValue, forKey: key)
    }
}
