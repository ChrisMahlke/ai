//
//  LocalModelProfile.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

enum LocalModelProfile: String, CaseIterable, Codable, Identifiable, Sendable {
    case smallFast
    case betterQuality

    var id: String {
        rawValue
    }

    var title: String {
        LocalModelRegistry.default.descriptor(for: self).title
    }

    var subtitle: String {
        LocalModelRegistry.default.descriptor(for: self).subtitle
    }

    var installationNote: String {
        LocalModelRegistry.default.descriptor(for: self).installationNote
    }

    var resource: LocalModelResource {
        LocalModelRegistry.default.resource(for: self)
    }
}
