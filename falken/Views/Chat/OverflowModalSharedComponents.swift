//
//  OverflowModalSharedComponents.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ModalPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.panelFill)
                    .stroke(AppTheme.panelStroke, lineWidth: 1)
            )
    }
}

struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.foreground.opacity(0.48))
            .textCase(.uppercase)
    }
}

struct DiagnosticRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.foreground.opacity(0.46))
                .frame(width: 96, alignment: .leading)

            Text(value)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppTheme.foreground.opacity(0.82))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PresetButton: View {
    let preset: LocalModelPreset
    let isSelected: Bool
    let isRecommended: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.foreground.opacity(0.9))

                    if isRecommended {
                        Text("Recommended")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.foreground.opacity(0.5))
                    }

                    Text(preset.subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppTheme.foreground.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? AppTheme.foreground.opacity(0.88) : AppTheme.foreground.opacity(0.24))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AppTheme.elevatedFill : AppTheme.panelFill)
                    .stroke(isSelected ? AppTheme.panelStroke.opacity(1.35) : AppTheme.panelStroke.opacity(0.75), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ProviderButton: View {
    let provider: ChatProvider
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: provider.systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 24, height: 24)
                        .background(AppTheme.subtleFill)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.foreground.opacity(0.9) : AppTheme.foreground.opacity(0.28))
                }

                Text(provider.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.foreground.opacity(0.9))

                Text(provider.subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppTheme.foreground.opacity(0.44))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 106, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AppTheme.elevatedFill : AppTheme.panelFill)
                    .stroke(isSelected ? AppTheme.panelStroke.opacity(1.35) : AppTheme.panelStroke.opacity(0.75), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ProviderHealthBadge: View {
    let status: ProviderStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(AppTheme.foreground.opacity(0.62))
        .padding(.horizontal, 9)
        .frame(height: 24)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.subtleFill)
        )
    }

    private var label: String {
        switch status.health {
        case .ready:
            return "Ready"
        case .loading:
            return "Loading"
        case .notConfigured:
            return "Not configured"
        case .unavailable:
            return "Unavailable"
        case .unknown:
            return "Idle"
        }
    }

    private var color: Color {
        switch status.health {
        case .ready:
            return .green.opacity(0.82)
        case .loading:
            return .yellow.opacity(0.82)
        case .notConfigured, .unknown:
            return AppTheme.foreground.opacity(0.34)
        case .unavailable:
            return .red.opacity(0.76)
        }
    }
}

struct IntegerSettingRow: View {
    let title: String
    let valueText: String
    let note: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.foreground.opacity(0.9))

                    Text(note)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppTheme.foreground.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Text(valueText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.foreground.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 58, alignment: .trailing)
            }

            HStack(spacing: 10) {
                adjustmentButton(systemName: "minus", isEnabled: value > range.lowerBound) {
                    value = max(range.lowerBound, value - step)
                }

                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { newValue in
                            value = clampedSteppedValue(newValue)
                        }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: Double(step)
                )
                .tint(AppTheme.foreground.opacity(0.86))

                adjustmentButton(systemName: "plus", isEnabled: value < range.upperBound) {
                    value = min(range.upperBound, value + step)
                }
            }
        }
    }

    private func adjustmentButton(
        systemName: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 32, height: 32)
                .background(AppTheme.foreground.opacity(isEnabled ? 0.1 : 0.05))
                .foregroundStyle(AppTheme.foreground.opacity(isEnabled ? 0.86 : 0.24))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func clampedSteppedValue(_ newValue: Double) -> Int {
        let stepped = Int((newValue / Double(step)).rounded()) * step
        return min(max(stepped, range.lowerBound), range.upperBound)
    }
}

struct DecimalSettingSlider: View {
    let title: String
    let valueText: String
    let note: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.foreground.opacity(0.9))

                    Text(note)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppTheme.foreground.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Text(valueText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.foreground.opacity(0.84))
                    .lineLimit(1)
                    .frame(minWidth: 46, alignment: .trailing)
            }

            Slider(value: $value, in: range, step: step)
                .tint(AppTheme.foreground.opacity(0.86))
        }
    }
}
