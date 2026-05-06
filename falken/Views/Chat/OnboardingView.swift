//
//  OnboardingView.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct OnboardingView: View {
    let readinessReport: OnDeviceReadinessReport
    let complete: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Spacer(minLength: 12)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppBrand.spacedName)
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .textCase(.lowercase)

                        Text(AppBrand.tagline)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.foreground.opacity(0.52))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Private, local-first chat on iPhone and iPad.")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(AppTheme.foreground.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Readiness")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.foreground.opacity(0.48))
                            .textCase(.uppercase)

                        ForEach(readinessReport.checks) { check in
                            readinessRow(check)
                        }
                    }

                    Text(readinessReport.hasBlockingIssue ? "You can continue, but local inference will stay unavailable until blocked checks are fixed and the app is rebuilt." : "This device is ready for local inference.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppTheme.foreground.opacity(0.52))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 14)

                    Button(action: complete) {
                        Text(readinessReport.hasBlockingIssue ? "Continue Anyway" : "Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppTheme.primaryAction)
                            .foregroundStyle(AppTheme.primaryActionText)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the chat screen")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: 520)
            }
        }
        .foregroundStyle(AppTheme.foreground)
    }

    private func readinessRow(_ check: OnDeviceReadinessReport.Check) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: check.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 30, height: 30)
                .foregroundStyle(statusColor(check.status))
                .background(statusColor(check.status).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(check.title)
                    .font(.system(size: 15, weight: .semibold))

                Text(check.detail)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.foreground.opacity(0.52))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func statusColor(_ status: OnDeviceReadinessReport.Check.Status) -> Color {
        switch status {
        case .ready:
            return .green.opacity(0.82)
        case .warning:
            return .yellow.opacity(0.82)
        case .blocked:
            return .red.opacity(0.76)
        }
    }
}
