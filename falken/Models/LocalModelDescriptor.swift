//
//  LocalModelDescriptor.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

struct LocalModelDescriptor: Equatable, Sendable {
    enum Family: String, Sendable {
        case gemma = "Gemma"
    }

    let profile: LocalModelProfile
    let family: Family
    let title: String
    let subtitle: String
    let installationNote: String
    let resource: LocalModelResource
}
