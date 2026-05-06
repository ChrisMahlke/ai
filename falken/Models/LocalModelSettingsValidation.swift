//
//  LocalModelSettingsValidation.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelSettingsValidation: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case notChecked
        case checking
        case valid
        case invalid(String)
    }

    var status: Status
    var requestedSettings: LocalModelSettings?
    var appliedSettings: LocalModelSettings?
    var validatedAt: Date?

    nonisolated static let notChecked = LocalModelSettingsValidation(
        status: .notChecked,
        requestedSettings: nil,
        appliedSettings: nil,
        validatedAt: nil
    )
}
