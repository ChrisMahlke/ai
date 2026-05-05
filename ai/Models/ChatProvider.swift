//
//  ChatProvider.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

enum ChatProvider: String, CaseIterable, Codable, Identifiable, Sendable {
    case local
    case gemini

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .local:
            return "Local"
        case .gemini:
            return "Gemini"
        }
    }

    var subtitle: String {
        switch self {
        case .local:
            return "Offline open-weight model"
        case .gemini:
            return "Remote SDK provider"
        }
    }

    var systemImage: String {
        switch self {
        case .local:
            return "iphone"
        case .gemini:
            return "sparkles"
        }
    }
}
