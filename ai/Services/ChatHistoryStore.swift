//
//  ChatHistoryStore.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct ChatHistoryStore {
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDirectory = supportDirectory.appendingPathComponent("ai", isDirectory: true)
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        self.fileURL = appDirectory.appendingPathComponent("chat-history.json")
    }

    func load() -> ChatHistorySnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        return try? JSONDecoder().decode(ChatHistorySnapshot.self, from: data)
    }

    func save(_ snapshot: ChatHistorySnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }

        try? data.write(to: fileURL, options: [.atomic])
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
