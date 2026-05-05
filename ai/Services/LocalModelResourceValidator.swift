//
//  LocalModelResourceValidator.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelResourceValidator {
    enum Result: Equatable {
        case valid(URL, UInt64)
        case invalid(String)
    }

    func validate(resource: LocalModelResource, bundle: Bundle = .main) -> Result {
        guard let modelURL = bundle.url(forResource: resource.name, withExtension: resource.fileExtension) else {
            return .invalid("Add \(resource.fileName) to the app bundle to enable offline responses.")
        }

        let path = modelURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            return .invalid("The bundled model path could not be read.")
        }

        guard FileManager.default.isReadableFile(atPath: path) else {
            return .invalid("The bundled model file is not readable.")
        }

        guard (try? modelURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
            return .invalid("The bundled model resource is not a regular file.")
        }

        let fileSizeBytes = Self.fileSize(at: modelURL)
        guard fileSizeBytes >= resource.minimumFileSizeBytes else {
            return .invalid("The bundled model file is smaller than expected. Reinstall \(resource.fileName).")
        }

        guard fileSizeBytes <= resource.maximumFileSizeBytes else {
            return .invalid("The bundled model file is larger than expected for this device profile.")
        }

        return .valid(modelURL, fileSizeBytes)
    }

    private static func fileSize(at url: URL) -> UInt64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return UInt64(values?.fileSize ?? 0)
    }
}
