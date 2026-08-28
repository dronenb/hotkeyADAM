import Foundation
import GRDB

/// Persists indexed shortcuts and answers shortcut lookups for clicked
/// elements.
final class ShortcutRepository: Sendable {
    private let appDatabase: AppDatabase

    init(appDatabase: AppDatabase) {
        self.appDatabase = appDatabase
    }

    // MARK: - Applications

    @discardableResult
    func upsertApplication(appName: String, bundleIdentifier: String) throws -> Int64 {
        try appDatabase.dbWriter.write { db in
            var app = ApplicationRecord(appName: appName, bundleIdentifier: bundleIdentifier)
            try app.upsert(db)
            if let id = app.id { return id }
            return try ApplicationRecord
                .filter(Column("bundle_identifier") == bundleIdentifier
                            && Column("app_name") == appName)
                .fetchOne(db)?
                .id ?? 0
        }
    }

    func applicationID(bundleIdentifier: String, appName: String) throws -> Int64? {
        try appDatabase.dbWriter.read { db in
            try ApplicationRecord
                .filter(Column("bundle_identifier") == bundleIdentifier && Column("app_name") == appName)
                .fetchOne(db)?
                .id
        }
    }

    // MARK: - Shortcuts

    @discardableResult
    func upsertShortcut(_ shortcutString: String) throws -> Int64 {
        try appDatabase.dbWriter.write { db in
            var shortcut = ShortcutRecord(shortcutString: shortcutString)
            try shortcut.upsert(db)
            return try shortcut.id ?? fetchShortcutID(shortcutString, in: db) ?? 0
        }
    }

    private func fetchShortcutID(_ string: String, in db: Database) throws -> Int64? {
        try ShortcutRecord.filter(Column("shortcut_string") == string).fetchOne(db)?.id
    }

    // MARK: - Menu bar items

    func upsertMenuBarItems(_ elements: [UIElement], applicationID: Int64) throws {
        try appDatabase.dbWriter.write { db in
            for element in elements {
                guard let shortcut = element.shortcutString else { continue }
                let shortcutID = try self.upsertShortcut(shortcut, in: db)
                var item = MenuBarItemRecord(
                    identifier: ElementIdentifier.identifier(for: element, appName: applicationName(for: applicationID, in: db)),
                    elementTitle: element.title,
                    elementHelp: element.help,
                    parentTitle: element.parentTitle,
                    shortcutID: shortcutID,
                    applicationID: applicationID)
                try item.upsert(db)
            }
        }
    }

    private func upsertShortcut(_ string: String, in db: Database) throws -> Int64 {
        var shortcut = ShortcutRecord(shortcutString: string)
        try shortcut.upsert(db)
        return try shortcut.id ?? fetchShortcutID(string, in: db) ?? 0
    }

    private func applicationName(for id: Int64, in db: Database) -> String {
        (try? ApplicationRecord.fetchOne(db, key: id))?.appName ?? ""
    }

    // MARK: - Lookup

    /// Returns the shortcut string associated with a clicked element, if
    /// present and not disabled.
    func shortcutString(for element: UIElement, appName: String) throws -> String? {
        try appDatabase.dbWriter.read { db in
            let appID = try ApplicationRecord
                .filter(Column("app_name") == appName)
                .fetchOne(db)?
                .id
            guard let appID else { return nil }

            let identifier = ElementIdentifier.identifier(for: element, appName: appName)
            let item = try MenuBarItemRecord
                .filter(Column("identifier") == identifier
                            && Column("application_id") == appID
                            && Column("element_title") == element.title)
                .fetchOne(db)
            guard let item, let shortcutID = item.shortcutID else { return nil }

            // Skip disabled hints.
            let disabledCount = try DisabledShortcutRecord
                .filter(Column("application_id") == appID
                            && Column("shortcut_id") == shortcutID
                            && Column("element_title") == element.title)
                .fetchCount(db)
            guard disabledCount == 0 else { return nil }

            return (try ShortcutRecord.fetchOne(db, key: shortcutID))?.shortcutString
        }
    }

    // MARK: - Disabling

    func disableShortcut(element: UIElement, appName: String, shortcutString: String) throws {
        try appDatabase.dbWriter.write { db in
            guard let appID = try ApplicationRecord
                .filter(Column("app_name") == appName)
                .fetchOne(db)?
                .id else { return }
            let shortcutID = try self.upsertShortcut(shortcutString, in: db)
            var record = DisabledShortcutRecord(applicationID: appID,
                                                shortcutID: shortcutID,
                                                elementTitle: element.title)
            try record.upsert(db)
        }
    }
}
