//
//  ChatViewModel+Lifecycle.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Combine
import UIKit

@MainActor
extension ChatViewModel {
    func observeLocalAIManager(_ manager: LocalAIManager) {
        manager.$loadState
            .receive(on: RunLoop.main)
            .sink { [weak self] loadState in
                Task { @MainActor [weak self] in
                    await Task.yield()
                    self?.updateBackendNotice(from: loadState)
                }
            }
            .store(in: &cancellables)

        manager.$activeModelProfile
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] activeModelProfile in
                guard let self else { return }

                Task { @MainActor [weak self] in
                    await Task.yield()
                    guard let self else { return }

                    if self.activeModelProfile != activeModelProfile {
                        self.activeModelProfile = activeModelProfile
                    }

                    let installedModels = manager.installedModels()
                    if self.installedModels != installedModels {
                        self.installedModels = installedModels
                    }
                }
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
