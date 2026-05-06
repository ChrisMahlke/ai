//
//  PromptTemplateStore.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct PromptTemplateStore {
    private let fileURL: URL

    nonisolated init(fileManager: FileManager = .default) {
        let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDirectory = supportDirectory.appendingPathComponent("falken", isDirectory: true)
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        self.fileURL = appDirectory.appendingPathComponent("prompt-templates.json")
    }

    nonisolated func load() -> [PromptTemplate] {
        guard let data = try? Data(contentsOf: fileURL),
              let savedTemplates = try? JSONDecoder().decode([PromptTemplate].self, from: data)
        else {
            return PromptTemplate.builtIns
        }

        let builtInIDs = Set(PromptTemplate.builtIns.map(\.id))
        let customTemplates = savedTemplates.filter { !$0.isBuiltIn && !builtInIDs.contains($0.id) }
        return PromptTemplate.builtIns + customTemplates.sorted { $0.createdAt > $1.createdAt }
    }

    nonisolated func save(_ templates: [PromptTemplate]) {
        let customTemplates = templates.filter { !$0.isBuiltIn }
        guard let data = try? JSONEncoder().encode(customTemplates) else { return }

        try? data.write(to: fileURL, options: [.atomic])
    }
}
