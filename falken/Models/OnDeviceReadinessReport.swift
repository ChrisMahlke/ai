//
//  OnDeviceReadinessReport.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

struct OnDeviceReadinessReport: Equatable, Sendable {
    struct Check: Identifiable, Equatable, Sendable {
        enum Status: Equatable, Sendable {
            case ready
            case warning
            case blocked
        }

        let id: String
        let title: String
        let detail: String
        let systemImage: String
        let status: Status
    }

    let checks: [Check]

    var hasBlockingIssue: Bool {
        checks.contains { $0.status == .blocked }
    }
}
