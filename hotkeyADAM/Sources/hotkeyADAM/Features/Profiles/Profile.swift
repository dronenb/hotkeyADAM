import Foundation

/// A user-imported profile describing the keyboard shortcuts of an application.
///
/// Profiles are opt-in and user-supplied; hotkeyADAM ships with zero bundled
/// profiles.
struct ShortcutProfile: Codable, Equatable {
    let bundleIdentifier: String
    let language: String
    let entries: [ShortcutProfileEntry]

    enum CodingKeys: String, CodingKey {
        case bundleIdentifier
        case language
        case entries
    }
}

/// A single shortcut entry within a profile.
struct ShortcutProfileEntry: Codable, Equatable {
    let uiElementIdentifier: String
    let cocoaIdentifier: String
    let title: String
    let help: String
    let shortcut: String

    enum CodingKeys: String, CodingKey {
        case uiElementIdentifier
        case cocoaIdentifier
        case title
        case help
        case shortcut
    }
}
