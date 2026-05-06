//
//  LocalModelMemoryPolicy.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation
import MachO
import UIKit

struct LocalModelMemoryPolicy {
    struct Snapshot: Equatable {
        let physicalMemoryBytes: UInt64
        let appMemoryBytes: UInt64?
        let modelFileBytes: UInt64
        let thermalState: ProcessInfo.ThermalState
    }

    enum Decision: Equatable {
        case allowed(Snapshot)
        case denied(Snapshot, String)
    }

    enum RuntimePressureDecision: Equatable {
        case safe
        case unload(String)
    }

    private let minimumPhysicalMemoryBytes: UInt64 = 3_500_000_000
    private let workingMemoryHeadroomBytes: UInt64 = 768 * 1_024 * 1_024
    private let maxProjectedMemoryRatio = 0.86
    private let maxRuntimeMemoryRatio = 0.88

    func evaluate(modelURL: URL) -> Decision {
        let snapshot = Snapshot(
            physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
            appMemoryBytes: Self.currentAppMemoryFootprint(),
            modelFileBytes: Self.fileSize(at: modelURL),
            thermalState: ProcessInfo.processInfo.thermalState
        )

        guard snapshot.physicalMemoryBytes >= minimumPhysicalMemoryBytes else {
            return .denied(snapshot, "This device does not have enough memory for the bundled local model.")
        }

        if snapshot.thermalState == .critical {
            return .denied(snapshot, "The device is under critical thermal pressure. Try again after it cools down.")
        }

        if let appMemoryBytes = snapshot.appMemoryBytes {
            let projectedBytes = appMemoryBytes + (snapshot.modelFileBytes * 2) + workingMemoryHeadroomBytes
            let projectedRatio = Double(projectedBytes) / Double(snapshot.physicalMemoryBytes)

            if projectedRatio > maxProjectedMemoryRatio {
                return .denied(snapshot, "There is not enough memory available to safely load the local model right now.")
            }
        }

        return .allowed(snapshot)
    }

    func evaluateRuntimePressure(appMemoryBytes: UInt64) -> RuntimePressureDecision {
        let thermalState = ProcessInfo.processInfo.thermalState
        if thermalState == .serious || thermalState == .critical {
            return .unload("Unloaded local model because the device reported \(thermalState.falkenDisplayName.lowercased()) thermal pressure.")
        }

        let memoryRatio = Double(appMemoryBytes) / Double(ProcessInfo.processInfo.physicalMemory)
        guard memoryRatio <= maxRuntimeMemoryRatio else {
            return .unload("Unloaded local model because app memory pressure became too high during generation.")
        }

        return .safe
    }

    static func fileSize(at url: URL) -> UInt64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return UInt64(values?.fileSize ?? 0)
    }

    static func currentAppMemoryFootprint() -> UInt64? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)

        let result = withUnsafeMutablePointer(to: &info) { infoPointer in
            infoPointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_VM_INFO),
                    reboundPointer,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        return UInt64(info.phys_footprint)
    }
}
