//
//  OverflowMenuView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct OverflowMenuView: View {
    let select: (OverflowMenuItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(OverflowMenuItem.allCases) { item in
                Button {
                    select(item)
                } label: {
                    Text(item.title)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppTheme.foreground.opacity(0.88))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 40)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 164)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.menuBackground)
                .stroke(AppTheme.foreground.opacity(0.12), lineWidth: 1)
                .shadow(color: AppTheme.composerShadow, radius: 18, y: 10)
        )
    }
}
