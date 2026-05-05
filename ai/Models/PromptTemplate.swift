//
//  PromptTemplate.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct PromptTemplate: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var title: String
    var text: String
    var category: String
    let createdAt: Date
    let isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        title: String,
        text: String,
        category: String = "Custom",
        createdAt: Date = Date(),
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.category = category
        self.createdAt = createdAt
        self.isBuiltIn = isBuiltIn
    }

    static let builtIns: [PromptTemplate] = [
        PromptTemplate(
            id: UUID(uuidString: "9C9E4FC8-1F68-47C2-8C04-3C19C4E751B2") ?? UUID(),
            title: "Summarize",
            text: "Summarize this clearly in a few concise bullet points:\n\n",
            category: "Writing",
            isBuiltIn: true
        ),
        PromptTemplate(
            id: UUID(uuidString: "4A42244F-0E5D-4E09-A22F-601961F1484B") ?? UUID(),
            title: "Improve writing",
            text: "Improve this text while keeping my voice. Make it clearer, tighter, and more natural:\n\n",
            category: "Writing",
            isBuiltIn: true
        ),
        PromptTemplate(
            id: UUID(uuidString: "58B15575-7CFD-4CEB-B08B-A6D68D0D71AE") ?? UUID(),
            title: "Explain simply",
            text: "Explain this in plain English. Use a short example if it helps:\n\n",
            category: "Learning",
            isBuiltIn: true
        ),
        PromptTemplate(
            id: UUID(uuidString: "7B54600D-710B-4082-B34F-8462EA47D9BF") ?? UUID(),
            title: "Plan next steps",
            text: "Turn this into a practical step-by-step plan with clear priorities:\n\n",
            category: "Planning",
            isBuiltIn: true
        )
    ]
}
