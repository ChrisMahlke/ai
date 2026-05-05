//
//  ChatViewModel+Lifecycle.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Combine
import UIKit

@MainActor
extension ChatViewModel {
    func observeLocalAIManager(_ manager: LocalAIManager) {
        manager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.activeModelProfile = manager.activeModelProfile
                self?.installedModels = manager.installedModels()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func observeApplicationLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.trimVisibleMessagesIfNeeded()
                self?.saveHistoryImmediately()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveHistoryImmediately()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveHistoryImmediately()
            }
            .store(in: &cancellables)
    }
}
