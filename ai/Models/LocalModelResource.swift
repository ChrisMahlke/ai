//
//  LocalModelResource.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelResource: Equatable, Sendable {
    let name: String
    let fileExtension: String
    let maxSequenceLength: Int

    var fileName: String {
        "\(name).\(fileExtension)"
    }

    nonisolated static let gemma3OneBInt4 = LocalModelResource(
        name: "google_gemma-3-1b-it-Q4_K_M",
        fileExtension: "gguf",
        maxSequenceLength: 2048
    )
}
