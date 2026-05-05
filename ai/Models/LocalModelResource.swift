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
    let minimumFileSizeBytes: UInt64
    let maximumFileSizeBytes: UInt64

    var fileName: String {
        "\(name).\(fileExtension)"
    }

    nonisolated static let gemma3OneBInt4 = LocalModelResource(
        name: "google_gemma-3-1b-it-Q4_K_M",
        fileExtension: "gguf",
        maxSequenceLength: 2048,
        minimumFileSizeBytes: 650 * 1_024 * 1_024,
        maximumFileSizeBytes: 900 * 1_024 * 1_024
    )

    nonisolated static let gemma3FourBInt4 = LocalModelResource(
        name: "google_gemma-3-4b-it-Q4_K_M",
        fileExtension: "gguf",
        maxSequenceLength: 4096,
        minimumFileSizeBytes: 2_400 * 1_024 * 1_024,
        maximumFileSizeBytes: 3_800 * 1_024 * 1_024
    )
}
