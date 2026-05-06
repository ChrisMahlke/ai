//
//  LocalInferenceTelemetryStore.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

struct LocalInferenceTelemetryStore {
    private let key = "localInferenceTelemetry.v1"
    private let defaults: UserDefaults

    nonisolated init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    nonisolated func load() -> LocalModelRuntimeTelemetry {
        guard let data = defaults.data(forKey: key),
              let telemetry = try? JSONDecoder().decode(LocalModelRuntimeTelemetry.self, from: data) else {
            return .empty
        }

        return telemetry
    }

    nonisolated func save(_ telemetry: LocalModelRuntimeTelemetry) {
        guard let data = try? JSONEncoder().encode(telemetry) else { return }

        defaults.set(data, forKey: key)
    }

    nonisolated func clear() {
        defaults.removeObject(forKey: key)
    }
}
