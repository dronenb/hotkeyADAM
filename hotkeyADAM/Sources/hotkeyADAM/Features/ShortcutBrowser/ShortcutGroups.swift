import Foundation

/// A group of shortcuts belonging to one application, for the browser.
struct ShortcutGroup: Identifiable {
    let appName: String
    let shortcuts: [ShortcutRow]

    var id: String { appName }
}

/// A single shortcut row in the browser.
struct ShortcutRow: Identifiable {
    enum Source {
        case indexed
        case profile
    }

    let title: String
    let shortcut: String
    let source: Source

    var id: String { title + shortcut }
}
