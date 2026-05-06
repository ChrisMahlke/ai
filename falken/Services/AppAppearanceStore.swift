//
//  AppAppearanceStore.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct AppAppearanceStore {
    private let defaults: UserDefaults
    private let key = "appAppearanceMode.v1"

    nonisolated init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    nonisolated func load() -> AppAppearanceMode {
        guard let rawValue = defaults.string(forKey: key),
              let mode = AppAppearanceMode(rawValue: rawValue)
        else {
            return .system
        }

        return mode
    }

    nonisolated func save(_ mode: AppAppearanceMode) {
        defaults.set(mode.rawValue, forKey: key)
    }
}
