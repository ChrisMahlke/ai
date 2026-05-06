//
//  SearchMatching.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

extension String {
    func localizedCaseInsensitiveMatchCount(of query: String) -> Int {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return 0 }

        var searchRange = startIndex..<endIndex
        var count = 0

        while let range = range(
            of: trimmedQuery,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: searchRange,
            locale: .current
        ) {
            count += 1
            searchRange = range.upperBound..<endIndex
        }

        return count
    }
}
