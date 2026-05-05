//
//  ChatSearchBarView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct ChatSearchBarView: View {
    @Binding var query: String
    let matchCount: Int

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.38))

            TextField("Search this chat", text: $query)
                .font(.system(size: 14, weight: .regular))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(matchCount == 1 ? "1 match" : "\(matchCount) matches")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.42))
                    .lineLimit(1)

                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.36))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear chat search")
            }
        }
        .foregroundStyle(.white.opacity(0.84))
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.055))
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }
}
