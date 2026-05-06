//
//  ChatRuntimeState.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

enum ChatRuntimeState: Equatable {
    case idle
    case loadingModel(progress: Double, message: String)
    case thinking
    case generating
    case failed(String)

    var isThinking: Bool {
        self == .thinking
    }

    var isGenerating: Bool {
        self == .generating
    }

    var loadingModel: (progress: Double, message: String)? {
        if case .loadingModel(let progress, let message) = self {
            return (progress, message)
        }

        return nil
    }

    var failureMessage: String? {
        if case .failed(let message) = self {
            return message
        }

        return nil
    }
}
