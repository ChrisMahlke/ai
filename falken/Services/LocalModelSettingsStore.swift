//
//  LocalModelSettingsStore.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelSettingsStore {
    private let key = "localModelSettings.v1"
    private let defaults: UserDefaults

    nonisolated init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    nonisolated func load() -> LocalModelSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(LocalModelSettings.self, from: data) else {
            return .default
        }

        return settings.clamped
    }

    nonisolated func save(_ settings: LocalModelSettings) {
        guard let data = try? JSONEncoder().encode(settings.clamped) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}
