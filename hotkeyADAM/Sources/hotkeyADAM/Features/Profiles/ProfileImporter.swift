import Foundation

/// Validates and decodes a profile from a JSON file.
enum ProfileImporter {

    /// Error thrown when a profile file cannot be imported.
    enum ImportError: LocalizedError {
        case unreadableFile
        case invalidJSON(String)
        case missingBundleIdentifier
        case invalidEntry(String)

        var errorDescription: String? {
            switch self {
            case .unreadableFile:
                return "The profile file could not be read."
            case .invalidJSON(let detail):
                return "The profile file is not valid JSON: \(detail)"
            case .missingBundleIdentifier:
                return "The profile is missing a bundleIdentifier."
            case .invalidEntry(let entry):
                return "Profile has an invalid entry: \(entry)"
            }
        }
    }

    /// Reads and validates a profile from the file at `url`.
    static func importProfile(from url: URL) throws -> ShortcutProfile {
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.unreadableFile
        }
        return try validate(data)
    }

    /// Validates raw profile JSON data.
    static func validate(_ data: Data) throws -> ShortcutProfile {
        let profile: ShortcutProfile
        do {
            profile = try JSONDecoder().decode(ShortcutProfile.self, from: data)
        } catch {
            throw ImportError.invalidJSON(error.localizedDescription)
        }

        guard !profile.bundleIdentifier.isEmpty else {
            throw ImportError.missingBundleIdentifier
        }

        for entry in profile.entries where entry.shortcut.isEmpty {
            throw ImportError.invalidEntry(entry.title.isEmpty
                ? entry.uiElementIdentifier
                : entry.title)
        }

        return profile
    }
}
