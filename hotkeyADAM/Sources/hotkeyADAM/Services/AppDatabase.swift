import Foundation
import GRDB

/// Owns the SQLite database connection and schema migrations.
///
/// This is a fresh schema for the rewrite (no legacy SQL carried over). The
/// profile (`gui_elements`) tables are added in Phase 3.
final class AppDatabase: Sendable {
    let dbWriter: any DatabaseWriter

    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }

    convenience init() throws {
        let databaseURL = try AppDatabase.databaseURL()
        let writer = try DatabasePool(path: databaseURL.path)
        try self.init(writer)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createApplicationsShortcutsAndMenuBarItems") { db in
            try db.create(table: "applications") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("app_name", .text)
                t.column("bundle_identifier", .text)
                t.uniqueKey(["bundle_identifier", "app_name"])
            }

            try db.create(table: "shortcuts") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("shortcut_string", .text).notNull().unique()
            }

            try db.create(table: "menu_bar_items") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("identifier", .text)
                t.column("element_title", .text)
                t.column("element_help", .text)
                t.column("parent_title", .text)
                t.column("shortcut_id", .integer).references("shortcuts", onDelete: .cascade)
                t.column("application_id", .integer).references("applications", onDelete: .cascade)
                t.uniqueKey(["identifier", "application_id", "element_title"])
            }
        }

        migrator.registerMigration("createDisabledShortcuts") { db in
            try db.create(table: "disabled_shortcuts") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("application_id", .integer).references("applications", onDelete: .cascade)
                t.column("shortcut_id", .integer).references("shortcuts", onDelete: .cascade)
                t.column("element_title", .text)
                t.uniqueKey(["application_id", "shortcut_id", "element_title"])
            }
        }

        return migrator
    }

    private static func databaseURL() throws -> URL {
        let fileManager = FileManager.default
        let supportDir = try fileManager.url(for: .applicationSupportDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil,
                                             create: true)
        let appDir = supportDir.appendingPathComponent("hotkeyADAM", isDirectory: true)
        try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("hotkeyadam.sqlite")
    }
}

// MARK: - Record types

/// An installed/handled application that has been indexed.
struct ApplicationRecord: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var appName: String
    var bundleIdentifier: String

    static let databaseTableName = "applications"

    enum CodingKeys: String, CodingKey {
        case id
        case appName = "app_name"
        case bundleIdentifier = "bundle_identifier"
    }
}

/// A keyboard shortcut string, stored once and referenced by items.
struct ShortcutRecord: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var shortcutString: String

    static let databaseTableName = "shortcuts"

    enum CodingKeys: String, CodingKey {
        case id
        case shortcutString = "shortcut_string"
    }
}

/// A menu-bar item that exposes a shortcut, discovered by indexing.
struct MenuBarItemRecord: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var identifier: String
    var elementTitle: String
    var elementHelp: String
    var parentTitle: String
    var shortcutID: Int64?
    var applicationID: Int64?

    static let databaseTableName = "menu_bar_items"

    enum CodingKeys: String, CodingKey {
        case id
        case identifier
        case elementTitle = "element_title"
        case elementHelp = "element_help"
        case parentTitle = "parent_title"
        case shortcutID = "shortcut_id"
        case applicationID = "application_id"
    }
}

/// A shortcut hint the user has asked not to show again.
struct DisabledShortcutRecord: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var applicationID: Int64?
    var shortcutID: Int64?
    var elementTitle: String

    static let databaseTableName = "disabled_shortcuts"

    enum CodingKeys: String, CodingKey {
        case id
        case applicationID = "application_id"
        case shortcutID = "shortcut_id"
        case elementTitle = "element_title"
    }
}
