//
//  BackgroundCleanupService.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

struct BackgroundCleanupService {
    let historyStore: ChatHistoryStore
    let telemetryStore: LocalInferenceTelemetryStore
    let historyPolicy: ChatHistoryPolicy
    let staleChatAge: TimeInterval
    let staleTelemetryAge: TimeInterval

    init(
        historyStore: ChatHistoryStore = ChatHistoryStore(),
        telemetryStore: LocalInferenceTelemetryStore = LocalInferenceTelemetryStore(),
        historyPolicy: ChatHistoryPolicy = .default,
        staleChatAge: TimeInterval = 60 * 60 * 24 * 90,
        staleTelemetryAge: TimeInterval = 60 * 60 * 24 * 30
    ) {
        self.historyStore = historyStore
        self.telemetryStore = telemetryStore
        self.historyPolicy = historyPolicy
        self.staleChatAge = staleChatAge
        self.staleTelemetryAge = staleTelemetryAge
    }

    func run() {
        // Cleanup is intentionally best-effort and local-only. It should never
        // block launch, require network access, or delete pinned conversations.
        cleanupHistory()
        cleanupTelemetry()
    }

    private func cleanupHistory(now: Date = Date()) {
        guard let snapshot = historyStore.load() else { return }

        let recentChats = snapshot.recentChats.filter { chat in
            chat.isPinned || now.timeIntervalSince(chat.updatedAt) <= staleChatAge
        }
        let prunedSnapshot = historyPolicy.pruneSnapshot(ChatHistorySnapshot(
            currentChatID: snapshot.currentChatID,
            currentTitleOverride: snapshot.currentTitleOverride,
            currentMessages: snapshot.currentMessages,
            recentChats: recentChats
        ))

        historyStore.save(prunedSnapshot)
    }

    private func cleanupTelemetry(now: Date = Date()) {
        let telemetry = telemetryStore.load()
        guard let lastLoadedAt = telemetry.lastLoadedAt else { return }
        guard now.timeIntervalSince(lastLoadedAt) > staleTelemetryAge else { return }

        telemetryStore.clear()
    }
}
