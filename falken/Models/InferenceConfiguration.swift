//
//  InferenceConfiguration.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

enum InferenceProvider: String, CaseIterable, Equatable, Sendable {
    case localOpenWeights
    case geminiSDK
}

struct InferenceConfiguration: Equatable, Sendable {
    var provider: InferenceProvider
    var localModelIdentifier: String
    var remoteModelIdentifier: String

    nonisolated static let `default` = InferenceConfiguration(
        provider: .localOpenWeights,
        localModelIdentifier: "gemma-3-1b-it-GGUF",
        remoteModelIdentifier: "gemini"
    )
}
