//
//  LocalAIManager.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Combine
import Foundation
import LlamaBackendKit
import UIKit

@MainActor
final class LocalAIManager: ObservableObject {
    static let shared = LocalAIManager()

    enum LoadState: Equatable {
        case idle
        case loading(progress: Double, message: String)
        case loaded
        case unavailable(String)
        case failed(String)
    }

    @Published var loadState: LoadState = .idle
    @Published var settings: LocalModelSettings
    @Published var diagnostics = LocalModelDiagnostics.empty
    @Published var activeModelProfile: LocalModelProfile

    var resource: LocalModelResource
    let configuration: InferenceConfiguration
    let engine = LlamaLocalEngine()
    let memoryPolicy = LocalModelMemoryPolicy()
    let resourceValidator = LocalModelResourceValidator()
    let settingsStore: LocalModelSettingsStore
    let modelProfileStore: LocalModelProfileStore
    let telemetryStore: LocalInferenceTelemetryStore
    var runtimeTelemetry = LocalModelRuntimeTelemetry.empty
    var settingsValidation = LocalModelSettingsValidation.notChecked
    var settingsTestResult = LocalModelSettingsTestResult.notRun
    var notificationObservers: [NSObjectProtocol] = []

    init(
        configuration: InferenceConfiguration = .default,
        settingsStore: LocalModelSettingsStore? = nil,
        modelProfileStore: LocalModelProfileStore? = nil,
        telemetryStore: LocalInferenceTelemetryStore? = nil
    ) {
        self.configuration = configuration
        let resolvedSettingsStore = settingsStore ?? LocalModelSettingsStore()
        let resolvedModelProfileStore = modelProfileStore ?? LocalModelProfileStore()
        let resolvedTelemetryStore = telemetryStore ?? LocalInferenceTelemetryStore()
        let resolvedModelProfile = resolvedModelProfileStore.load()
        self.settingsStore = resolvedSettingsStore
        self.modelProfileStore = resolvedModelProfileStore
        self.telemetryStore = resolvedTelemetryStore
        self.settings = resolvedSettingsStore.load()
        self.activeModelProfile = resolvedModelProfile
        self.resource = resolvedModelProfile.resource
        self.runtimeTelemetry = resolvedTelemetryStore.load()

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.unloadModel(reason: "Unloaded local model after system memory warning.")
            }
        })

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleThermalStateChange(ProcessInfo.processInfo.thermalState)
            }
        })

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.unloadModel(reason: "Unloaded local model while the app is in the background.")
            }
        })

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.unloadModel(reason: "Unloaded local model before app termination.")
            }
        })
    }

    deinit {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

}
