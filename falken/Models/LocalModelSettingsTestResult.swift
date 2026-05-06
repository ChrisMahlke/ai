//
//  LocalModelSettingsTestResult.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelSettingsTestResult: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case notRun
        case running
        case passed(String)
        case failed(String)
    }

    var status: Status
    var duration: TimeInterval?
    var testedAt: Date?

    nonisolated static let notRun = LocalModelSettingsTestResult(
        status: .notRun,
        duration: nil,
        testedAt: nil
    )
}
