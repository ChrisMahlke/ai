//
//  ProviderStatus.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct ProviderStatus: Equatable, Sendable {
    enum Health: Equatable, Sendable {
        case ready
        case loading
        case notConfigured
        case unavailable
        case unknown
    }

    let provider: ChatProvider
    let health: Health
    let title: String
    let detail: String

    var isReady: Bool {
        health == .ready
    }
}
