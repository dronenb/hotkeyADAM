import GRDB
import XCTest
@testable import hotkeyADAM

final class ElementIdentifierTests: XCTestCase {
    func testLegacyFormatRoleRoleDescriptionAppName() {
        let element = makeElement(role: "AXButton", roleDescription: "button")
        XCTAssertEqual(ElementIdentifier.identifier(for: element, appName: "Safari"),
                       "axbuttonbuttonsafari")
    }

    func testSpacesRemovedAndLowercased() {
        let element = makeElement(role: "AX Menu Item", roleDescription: "Menu Item")
        XCTAssertEqual(ElementIdentifier.identifier(for: element, appName: "My App"),
                       "axmenuitemmenuitemmyapp")
    }

    func testEmptyPartsOmitted() {
        let element = makeElement(role: "", roleDescription: "button")
        XCTAssertEqual(ElementIdentifier.identifier(for: element, appName: "Notes"),
                       "buttonnotes")
    }

    func testCocoaIdentifierIgnoresEmptyAttribute() {
        XCTAssertEqual(ElementIdentifier.cocoaIdentifier(role: "AXButton",
                                                         roleDescription: "button",
                                                         title: "New Tab",
                                                         elementDescription: "",
                                                         cocoaAttribute: ""),
                       "")
    }

    func testCocoaIdentifierConcatenates() {
        XCTAssertEqual(ElementIdentifier.cocoaIdentifier(role: "AXButton",
                                                         roleDescription: "button",
                                                         title: "New Tab",
                                                         elementDescription: "d",
                                                         cocoaAttribute: "newTab"),
                       "axbuttonbuttonnewtabdnewtab")
    }

    private func makeElement(role: String, roleDescription: String) -> UIElement {
        UIElement(role: role,
                  roleDescription: roleDescription,
                  subrole: "",
                  title: "",
                  help: "",
                  elementDescription: "",
                  parentTitle: "",
                  value: "",
                  cocoaIdentifier: "",
                  shortcutString: nil)
    }
}

final class ShortcutRepositoryTests: XCTestCase {
    private func makeRepository() throws -> (AppDatabase, ShortcutRepository) {
        let db = try AppDatabase(DatabaseQueue())
        return (db, ShortcutRepository(appDatabase: db))
    }

    private func element(title: String, shortcut: String?) -> UIElement {
        UIElement(role: "AXMenuItem",
                  roleDescription: "menu item",
                  subrole: "",
                  title: title,
                  help: "",
                  elementDescription: "",
                  parentTitle: "",
                  value: "",
                  cocoaIdentifier: "",
                  shortcutString: shortcut)
    }

    func testUpsertAndLookupShortcut() throws {
        let (_, repo) = try makeRepository()
        let appID = try repo.upsertApplication(appName: "Safari", bundleIdentifier: "com.apple.Safari")
        try repo.upsertMenuBarItems([element(title: "New Tab", shortcut: "Command T")],
                                    applicationID: appID)

        let clicked = element(title: "New Tab", shortcut: nil)
        XCTAssertEqual(try repo.shortcutString(for: clicked, appName: "Safari"), "Command T")
    }

    func testUnknownElementReturnsNil() throws {
        let (_, repo) = try makeRepository()
        let appID = try repo.upsertApplication(appName: "Safari", bundleIdentifier: "com.apple.Safari")
        try repo.upsertMenuBarItems([element(title: "New Tab", shortcut: "Command T")],
                                    applicationID: appID)

        let other = element(title: "Close Tab", shortcut: nil)
        XCTAssertNil(try repo.shortcutString(for: other, appName: "Safari"))
    }

    func testDisabledShortcutSuppressesResult() throws {
        let (_, repo) = try makeRepository()
        let appID = try repo.upsertApplication(appName: "Safari", bundleIdentifier: "com.apple.Safari")
        try repo.upsertMenuBarItems([element(title: "New Tab", shortcut: "Command T")],
                                    applicationID: appID)

        try repo.disableShortcut(element: element(title: "New Tab", shortcut: nil),
                                 appName: "Safari",
                                 shortcutString: "Command T")

        let clicked = element(title: "New Tab", shortcut: nil)
        XCTAssertNil(try repo.shortcutString(for: clicked, appName: "Safari"))
    }
}
