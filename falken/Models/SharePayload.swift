//
//  SharePayload.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct SharePayload: Identifiable, Equatable {
    let id = UUID()
    let text: String
}
