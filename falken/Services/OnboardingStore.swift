//
//  OnboardingStore.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct OnboardingStore {
    private let defaults: UserDefaults
    private let key = "onboardingCompleted.v1"

    nonisolated init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    nonisolated func isCompleted() -> Bool {
        defaults.bool(forKey: key)
    }

    nonisolated func markCompleted() {
        defaults.set(true, forKey: key)
    }
}
