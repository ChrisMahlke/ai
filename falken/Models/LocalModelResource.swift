//
//  LocalModelResource.swift
//  falken
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

}
