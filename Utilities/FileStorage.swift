//
// FileStorage.swift
// MacDroid
//
// Small Codable helper. Services use this to save settings, game library
// metadata, and key mapping profiles as beginner-readable JSON files.

import Foundation

enum FileStorage {
    static func load<T: Decodable>(_ type: T.Type, from url: URL) throws -> T? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder.macDroid.decode(type, from: data)
    }

    static func save<T: Encodable>(_ value: T, to url: URL) throws {
        try AppPaths.ensureApplicationSupportDirectory()
        let data = try JSONEncoder.macDroid.encode(value)
        try data.write(to: url, options: [.atomic])
    }
}

extension JSONEncoder {
    static var macDroid: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var macDroid: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

