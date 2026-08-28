import Foundation

/// Error thrown when the profile store is unavailable.
enum ProfileStoreError: Error {
    case unavailable
}

/// Stores user-imported shortcut profiles as JSON files and answers opt-in
/// shortcut lookups from them.
///
/// hotkeyADAM ships with zero bundled profiles; everything here is imported by
/// the user.
final class ProfileStore {
    private let fileManager: FileManager
    private let directory: URL

    init(fileManager: FileManager = .default, directory: URL? = nil) throws {
        self.fileManager = fileManager
        if let directory {
            self.directory = directory
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } else {
            let base = try fileManager.url(for: .applicationSupportDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil,
                                           create: true)
                .appendingPathComponent("hotkeyADAM", isDirectory: true)
                .appendingPathComponent("Profiles", isDirectory: true)
            try fileManager.createDirectory(at: base, withIntermediateDirectories: true)
            self.directory = base
        }
    }

    /// All profiles currently stored on disk.
    var profiles: [ShortcutProfile] {
        (try? loadAll()) ?? []
    }

    /// Validates and imports a profile file, storing a copy for later use.
    @discardableResult
    func importProfile(from url: URL) throws -> ShortcutProfile {
        let profile = try ProfileImporter.importProfile(from: url)
        try save(profile)
        return profile
    }

    func removeProfile(bundleIdentifier: String) {
        let prefix = sanitize(bundleIdentifier) + "."
        for url in (try? fileManager.contentsOfDirectory(at: directory,
                                                         includingPropertiesForKeys: nil)) ?? [] {
            if url.lastPathComponent.hasPrefix(prefix),
               url.pathExtension == "json" {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    /// Returns the shortcut for an element from an imported profile, if the
    /// importing user opted in by providing a profile for the app. `nil`
    /// otherwise.
    func shortcut(for element: UIElement, appName: String, bundleIdentifier: String) -> String? {
        guard let profile = profiles.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            return nil
        }

        let identifier = ElementIdentifier.identifier(for: element, appName: appName)

        for entry in profile.entries {
            // Match on the stable, user-facing title first; fall back to the
            // legacy identifier fields for compatibility with existing profiles.
            if !entry.title.isEmpty, entry.title == element.title {
                return entry.shortcut
            }
            if !entry.uiElementIdentifier.isEmpty, entry.uiElementIdentifier == identifier {
                return entry.shortcut
            }
            if !entry.cocoaIdentifier.isEmpty, entry.cocoaIdentifier == element.cocoaIdentifier {
                return entry.shortcut
            }
        }
        return nil
    }

    // MARK: - Persistence

    private func save(_ profile: ShortcutProfile) throws {
        let data = try JSONEncoder().encode(profile)
        try data.write(to: fileURL(for: profile), options: .atomic)
    }

    private func loadAll() throws -> [ShortcutProfile] {
        let urls = try fileManager.contentsOfDirectory(at: directory,
                                                       includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        var result = [ShortcutProfile]()
        for url in urls {
            if let data = try? Data(contentsOf: url),
               let profile = try? JSONDecoder().decode(ShortcutProfile.self, from: data) {
                result.append(profile)
            }
        }
        return result
    }

    private func fileURL(for profile: ShortcutProfile) -> URL {
        let base = "\(sanitize(profile.bundleIdentifier)).\(sanitize(profile.language))"
        return directory.appendingPathComponent("\(base).json")
    }

    private func sanitize(_ string: String) -> String {
        string
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "/", with: "_")
    }
}
