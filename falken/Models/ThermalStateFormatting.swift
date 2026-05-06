//
//  ThermalStateFormatting.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

extension ProcessInfo.ThermalState {
    var falkenDisplayName: String {
        switch self {
        case .nominal:
            return "Nominal"
        case .fair:
            return "Fair"
        case .serious:
            return "Serious"
        case .critical:
            return "Critical"
        @unknown default:
            return "Unknown"
        }
    }
}
