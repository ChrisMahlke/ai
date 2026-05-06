//
//  OnDeviceReadinessEvaluator.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation
import UIKit

struct OnDeviceReadinessEvaluator {
    private let storageWarningThresholdBytes: UInt64 = 1_000_000_000

    let validator: LocalModelResourceValidator
    let memoryPolicy: LocalModelMemoryPolicy

    init(
        validator: LocalModelResourceValidator = LocalModelResourceValidator(),
        memoryPolicy: LocalModelMemoryPolicy = LocalModelMemoryPolicy()
    ) {
        self.validator = validator
        self.memoryPolicy = memoryPolicy
    }

    func evaluate(activeModelProfile: LocalModelProfile, bundle: Bundle = .main) -> OnDeviceReadinessReport {
        let resource = activeModelProfile.resource
        let inspection = validator.inspect(resource: resource, bundle: bundle)
        let checks = [
            modelFoundCheck(resource: resource, inspection: inspection),
            targetMembershipCheck(resource: resource, inspection: inspection),
            signingAndDeviceCheck(),
            capacityCheck(resource: resource, inspection: inspection)
        ]

        return OnDeviceReadinessReport(checks: checks)
    }

    private func modelFoundCheck(
        resource: LocalModelResource,
        inspection: LocalModelResourceValidator.Inspection
    ) -> OnDeviceReadinessReport.Check {
        OnDeviceReadinessReport.Check(
            id: "model-found",
            title: inspection.isFound ? "Model found" : "Model missing",
            detail: inspection.isFound
            ? "\(resource.fileName) is present in the app bundle."
            : "Add \(resource.fileName) to falken/Models before building.",
            systemImage: inspection.isFound ? "checkmark.circle" : "exclamationmark.triangle",
            status: inspection.isFound ? .ready : .blocked
        )
    }

    private func targetMembershipCheck(
        resource: LocalModelResource,
        inspection: LocalModelResourceValidator.Inspection
    ) -> OnDeviceReadinessReport.Check {
        let isReady = inspection.hasValidTargetMembership
        return OnDeviceReadinessReport.Check(
            id: "target-membership",
            title: isReady ? "Target membership valid" : "Target membership needed",
            detail: isReady
            ? "The bundled file is readable by the falken target."
            : "In Xcode, select \(resource.fileName) and enable the falken target membership.",
            systemImage: isReady ? "checkmark.seal" : "target",
            status: isReady ? .ready : .blocked
        )
    }

    private func signingAndDeviceCheck() -> OnDeviceReadinessReport.Check {
        #if targetEnvironment(simulator)
        return OnDeviceReadinessReport.Check(
            id: "device-signing",
            title: "Physical device recommended",
            detail: "Choose a connected iPhone or iPad and a valid signing team before judging local inference performance.",
            systemImage: "iphone.slash",
            status: .warning
        )
        #else
        return OnDeviceReadinessReport.Check(
            id: "device-signing",
            title: "Device and signing ready",
            detail: "This build is installed on a physical iOS device.",
            systemImage: "iphone",
            status: .ready
        )
        #endif
    }

    private func capacityCheck(
        resource: LocalModelResource,
        inspection: LocalModelResourceValidator.Inspection
    ) -> OnDeviceReadinessReport.Check {
        let memoryStatus = memoryStatus(resource: resource, inspection: inspection)
        let storageStatus = storageStatus()
        let status = combinedStatus(memoryStatus.status, storageStatus.status)

        return OnDeviceReadinessReport.Check(
            id: "capacity",
            title: status == .ready ? "RAM and storage ready" : "Check RAM and storage",
            detail: "\(memoryStatus.detail) \(storageStatus.detail)",
            systemImage: status == .ready ? "memorychip" : "externaldrive.badge.exclamationmark",
            status: status
        )
    }

    private func memoryStatus(
        resource: LocalModelResource,
        inspection: LocalModelResourceValidator.Inspection
    ) -> (status: OnDeviceReadinessReport.Check.Status, detail: String) {
        guard let modelURL = inspection.url, inspection.isValid else {
            return (.blocked, "Memory safety can be checked after \(resource.fileName) is bundled.")
        }

        switch memoryPolicy.evaluate(modelURL: modelURL) {
        case .allowed:
            return (.ready, "Current memory and thermal state can load \(resource.fileName).")
        case .denied(_, let reason):
            return (.blocked, reason)
        }
    }

    private func storageStatus() -> (status: OnDeviceReadinessReport.Check.Status, detail: String) {
        guard let availableBytes = Self.availableStorageBytes() else {
            return (.warning, "Free storage could not be measured.")
        }

        guard availableBytes >= storageWarningThresholdBytes else {
            return (.warning, "Free storage is low; keep at least 1 GB available for development builds and caches.")
        }

        return (.ready, "Free storage is available for local runtime files.")
    }

    private func combinedStatus(
        _ lhs: OnDeviceReadinessReport.Check.Status,
        _ rhs: OnDeviceReadinessReport.Check.Status
    ) -> OnDeviceReadinessReport.Check.Status {
        if lhs == .blocked || rhs == .blocked {
            return .blocked
        }

        if lhs == .warning || rhs == .warning {
            return .warning
        }

        return .ready
    }

    private static func availableStorageBytes() -> UInt64? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let values = try? documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        guard let availableCapacity = values?.volumeAvailableCapacityForImportantUsage else {
            return nil
        }

        return UInt64(max(availableCapacity, 0))
    }
}
