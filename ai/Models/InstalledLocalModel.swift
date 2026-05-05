//
//  InstalledLocalModel.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct InstalledLocalModel: Identifiable, Equatable, Sendable {
    let profile: LocalModelProfile
    let isInstalled: Bool
    let fileSizeBytes: UInt64
    let statusText: String

    var id: String {
        profile.id
    }
}
