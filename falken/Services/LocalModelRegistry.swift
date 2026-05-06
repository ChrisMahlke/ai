//
//  LocalModelRegistry.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

nonisolated struct LocalModelRegistry {
    nonisolated static let `default` = LocalModelRegistry()

    let descriptors: [LocalModelDescriptor]

    init(descriptors: [LocalModelDescriptor]? = nil) {
        self.descriptors = descriptors ?? [
            LocalModelDescriptor(
                profile: .smallFast,
                family: .gemma,
                title: "Small / Fast",
                subtitle: "1B quantized model, recommended for iPhone 11 Pro.",
                installationNote: "Install google_gemma-3-1b-it-Q4_K_M.gguf in falken/Models and include it in the app target.",
                resource: LocalModelResource(
                    name: "google_gemma-3-1b-it-Q4_K_M",
                    fileExtension: "gguf",
                    maxSequenceLength: 2048,
                    minimumFileSizeBytes: 650 * 1_024 * 1_024,
                    maximumFileSizeBytes: 900 * 1_024 * 1_024
                )
            ),
            LocalModelDescriptor(
                profile: .betterQuality,
                family: .gemma,
                title: "Better Quality",
                subtitle: "Larger 4B quantized model for devices with more memory.",
                installationNote: "Install google_gemma-3-4b-it-Q4_K_M.gguf in falken/Models and include it in the app target. Use on higher-memory devices only.",
                resource: LocalModelResource(
                    name: "google_gemma-3-4b-it-Q4_K_M",
                    fileExtension: "gguf",
                    maxSequenceLength: 4096,
                    minimumFileSizeBytes: 2_400 * 1_024 * 1_024,
                    maximumFileSizeBytes: 3_800 * 1_024 * 1_024
                )
            )
        ]
    }

    var profiles: [LocalModelProfile] {
        descriptors.map(\.profile)
    }

    func descriptor(for profile: LocalModelProfile) -> LocalModelDescriptor {
        descriptors.first { $0.profile == profile } ?? descriptors[0]
    }

    func resource(for profile: LocalModelProfile) -> LocalModelResource {
        descriptor(for: profile).resource
    }
}
