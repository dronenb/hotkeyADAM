import XCTest
@testable import hotkeyADAM

final class ProfileImporterTests: XCTestCase {
    func testValidProfileDecodes() throws {
        let json = """
        {
          "bundleIdentifier": "com.apple.Safari",
          "language": "en",
          "entries": [
            {
              "uiElementIdentifier": "axmenuitemmenuitemsafarinewtab",
              "cocoaIdentifier": "",
              "title": "New Tab",
              "help": "",
              "shortcut": "Command T"
            }
          ]
        }
        """
        let profile = try ProfileImporter.validate(Data(json.utf8))
        XCTAssertEqual(profile.bundleIdentifier, "com.apple.Safari")
        XCTAssertEqual(profile.entries.count, 1)
        XCTAssertEqual(profile.entries[0].shortcut, "Command T")
    }

    func testMissingBundleIdentifierThrows() {
        let json = """
        { "language": "en", "entries": [] }
        """
        XCTAssertThrowsError(try ProfileImporter.validate(Data(json.utf8)))
    }

    func testEmptyShortcutThrows() {
        let json = """
        {
          "bundleIdentifier": "com.apple.Safari",
          "language": "en",
          "entries": [
            { "uiElementIdentifier": "x", "cocoaIdentifier": "", "title": "New Tab", "help": "", "shortcut": "" }
          ]
        }
        """
        XCTAssertThrowsError(try ProfileImporter.validate(Data(json.utf8)))
    }
}

final class ProfileStoreTests: XCTestCase {
    private func makeStore() throws -> (URL, URL, ProfileStore) {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("hotkeyADAM-tests-\(UUID().uuidString)")
        let storeDir = base.appendingPathComponent("store")
        let sourceDir = base.appendingPathComponent("source")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        return (storeDir, sourceDir, try ProfileStore(directory: storeDir))
    }

    private func writeProfile(to dir: URL, named: String, bundle: String) throws -> URL {
        let json = """
        {
          "bundleIdentifier": "\(bundle)",
          "language": "en",
          "entries": [
            {
              "uiElementIdentifier": "axmenuitemmenuitemsafarinewtab",
              "cocoaIdentifier": "",
              "title": "New Tab",
              "help": "",
              "shortcut": "Command T"
            }
          ]
        }
        """
        let url = dir.appendingPathComponent(named)
        try Data(json.utf8).write(to: url)
        return url
    }

    func testImportPersistsAndLoads() throws {
        let (storeDir, sourceDir, store) = try makeStore()
        defer { try? FileManager.default.removeItem(at: storeDir.deletingLastPathComponent()) }

        let url = try writeProfile(to: sourceDir, named: "profile.json", bundle: "com.apple.Safari")
        try store.importProfile(from: url)

        XCTAssertEqual(store.profiles.count, 1)
        XCTAssertEqual(store.profiles.first?.bundleIdentifier, "com.apple.Safari")
    }

    func testShortcutLookupByIdentifier() throws {
        let (storeDir, sourceDir, store) = try makeStore()
        defer { try? FileManager.default.removeItem(at: storeDir.deletingLastPathComponent()) }

        let url = try writeProfile(to: sourceDir, named: "profile.json", bundle: "com.apple.Safari")
        try store.importProfile(from: url)

        let element = UIElement(role: "AXMenuItem",
                                roleDescription: "menu item",
                                subrole: "",
                                title: "New Tab",
                                help: "",
                                elementDescription: "",
                                parentTitle: "",
                                value: "",
                                cocoaIdentifier: "",
                                shortcutString: nil)
        XCTAssertEqual(store.shortcut(for: element, appName: "Safari", bundleIdentifier: "com.apple.Safari"),
                       "Command T")
    }

    func testNoProfileForAppReturnsNil() throws {
        let (storeDir, sourceDir, store) = try makeStore()
        defer { try? FileManager.default.removeItem(at: storeDir.deletingLastPathComponent()) }

        let element = UIElement(role: "AXMenuItem",
                                roleDescription: "menu item",
                                subrole: "",
                                title: "New Tab",
                                help: "",
                                elementDescription: "",
                                parentTitle: "",
                                value: "",
                                cocoaIdentifier: "",
                                shortcutString: nil)
        XCTAssertNil(store.shortcut(for: element, appName: "Safari", bundleIdentifier: "com.apple.Safari"))
    }
}
