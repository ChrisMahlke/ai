//
//  LocalModelResourceValidator.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelResourceValidator {
    let registry: LocalModelRegistry

    init(registry: LocalModelRegistry = .default) {
        self.registry = registry
    }

    struct Inspection: Equatable {
        let url: URL?
        let fileExists: Bool
        let isReadable: Bool
        let isRegularFile: Bool
        let fileSizeBytes: UInt64
        let result: Result

        var isFound: Bool {
            url != nil && fileExists
        }

        var hasValidTargetMembership: Bool {
            isFound && isReadable && isRegularFile
        }

        var isValid: Bool {
            if case .valid = result {
                return true
            }

            return false
        }
    }

    enum Result: Equatable {
        case valid(URL, UInt64)
        case invalid(String)
    }

    func installedModel(for profile: LocalModelProfile, bundle: Bundle = .main) -> InstalledLocalModel {
        switch validate(resource: profile.resource, bundle: bundle) {
        case .valid(_, let fileSizeBytes):
            return InstalledLocalModel(
                profile: profile,
                isInstalled: true,
                fileSizeBytes: fileSizeBytes,
                statusText: "Installed"
            )
        case .invalid(let message):
            return InstalledLocalModel(
                profile: profile,
                isInstalled: false,
                fileSizeBytes: 0,
                statusText: message
            )
        }
    }

    func installedModels(bundle: Bundle = .main) -> [InstalledLocalModel] {
        registry.profiles.map { installedModel(for: $0, bundle: bundle) }
    }

    func validate(resource: LocalModelResource, bundle: Bundle = .main) -> Result {
        inspect(resource: resource, bundle: bundle).result
    }

    func inspect(resource: LocalModelResource, bundle: Bundle = .main) -> Inspection {
        guard let modelURL = bundle.url(forResource: resource.name, withExtension: resource.fileExtension) else {
            return Inspection(
                url: nil,
                fileExists: false,
                isReadable: false,
                isRegularFile: false,
                fileSizeBytes: 0,
                result: .invalid("Add \(resource.fileName) to the app bundle to enable offline responses.")
            )
        }

        let path = modelURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            return Inspection(
                url: modelURL,
                fileExists: false,
                isReadable: false,
                isRegularFile: false,
                fileSizeBytes: 0,
                result: .invalid("The bundled model path could not be read.")
            )
        }

        guard FileManager.default.isReadableFile(atPath: path) else {
            return Inspection(
                url: modelURL,
                fileExists: true,
                isReadable: false,
                isRegularFile: false,
                fileSizeBytes: Self.fileSize(at: modelURL),
                result: .invalid("The bundled model file is not readable.")
            )
        }

        let isRegularFile = (try? modelURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        let fileSizeBytes = Self.fileSize(at: modelURL)

        guard isRegularFile else {
            return Inspection(
                url: modelURL,
                fileExists: true,
                isReadable: true,
                isRegularFile: false,
                fileSizeBytes: fileSizeBytes,
                result: .invalid("The bundled model resource is not a regular file.")
            )
        }

        guard fileSizeBytes >= resource.minimumFileSizeBytes else {
            return Inspection(
                url: modelURL,
                fileExists: true,
                isReadable: true,
                isRegularFile: true,
                fileSizeBytes: fileSizeBytes,
                result: .invalid("The bundled model file is smaller than expected. Reinstall \(resource.fileName).")
            )
        }

        guard fileSizeBytes <= resource.maximumFileSizeBytes else {
            return Inspection(
                url: modelURL,
                fileExists: true,
                isReadable: true,
                isRegularFile: true,
                fileSizeBytes: fileSizeBytes,
                result: .invalid("The bundled model file is larger than expected for this device profile.")
            )
        }

        return Inspection(
            url: modelURL,
            fileExists: true,
            isReadable: true,
            isRegularFile: true,
            fileSizeBytes: fileSizeBytes,
            result: .valid(modelURL, fileSizeBytes)
        )
    }

    private static func fileSize(at url: URL) -> UInt64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return UInt64(values?.fileSize ?? 0)
    }
}
