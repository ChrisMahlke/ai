//
//  AppTheme.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI
import UIKit

enum AppTheme {
    static let background = dynamicColor(
        dark: UIColor(red: 0.055, green: 0.055, blue: 0.055, alpha: 1),
        light: UIColor(red: 0.972, green: 0.972, blue: 0.965, alpha: 1)
    )

    static let drawerBackground = dynamicColor(
        dark: UIColor(red: 0.075, green: 0.075, blue: 0.075, alpha: 1),
        light: UIColor(red: 0.945, green: 0.945, blue: 0.935, alpha: 1)
    )

    static let menuBackground = dynamicColor(
        dark: UIColor(red: 0.105, green: 0.105, blue: 0.105, alpha: 1),
        light: UIColor(red: 0.985, green: 0.985, blue: 0.978, alpha: 1)
    )

    static let foreground = dynamicColor(dark: .white, light: .black)
    static let inverseForeground = dynamicColor(dark: .black, light: .white)
    static let primaryAction = dynamicColor(dark: .white, light: .black)
    static let primaryActionText = dynamicColor(dark: .black, light: .white)

    static let panelFill = dynamicColor(
        dark: UIColor.white.withAlphaComponent(0.055),
        light: UIColor.black.withAlphaComponent(0.045)
    )
    static let panelStroke = dynamicColor(
        dark: UIColor.white.withAlphaComponent(0.10),
        light: UIColor.black.withAlphaComponent(0.10)
    )
    static let subtleFill = dynamicColor(
        dark: UIColor.white.withAlphaComponent(0.075),
        light: UIColor.black.withAlphaComponent(0.055)
    )
    static let elevatedFill = dynamicColor(
        dark: UIColor.white.withAlphaComponent(0.10),
        light: UIColor.black.withAlphaComponent(0.08)
    )
    static let scrim = dynamicColor(
        dark: UIColor.black.withAlphaComponent(0.44),
        light: UIColor.black.withAlphaComponent(0.20)
    )
    static let composerShadow = dynamicColor(
        dark: UIColor.black.withAlphaComponent(0.28),
        light: UIColor.black.withAlphaComponent(0.10)
    )

    private static func dynamicColor(dark: UIColor, light: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
