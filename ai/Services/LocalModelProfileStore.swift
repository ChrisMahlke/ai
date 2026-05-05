//
//  LocalModelProfileStore.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelProfileStore {
    private let defaults: UserDefaults
    private let key = "localModelProfile.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> LocalModelProfile {
        guard let rawValue = defaults.string(forKey: key),
              let profile = LocalModelProfile(rawValue: rawValue)
        else {
            return .smallFast
        }

        return profile
    }

    func save(_ profile: LocalModelProfile) {
        defaults.set(profile.rawValue, forKey: key)
    }
}
