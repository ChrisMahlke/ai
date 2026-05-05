//
//  OnboardingStore.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct OnboardingStore {
    private let defaults: UserDefaults
    private let key = "onboardingCompleted.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isCompleted() -> Bool {
        defaults.bool(forKey: key)
    }

    func markCompleted() {
        defaults.set(true, forKey: key)
    }
}
