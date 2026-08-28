import AppKit
import ApplicationServices
import Foundation

/// Coordinates shortcut indexing and click handling. It is the bridge between
/// the low-level AX/indexer services and the persistence + notification
/// layers.
final class IndexingService {
    private let indexer: MenuBarIndexer
    private let repository: ShortcutRepository
    private let notifications: NotificationService
    private let profileStore: ProfileStore?

    init(indexer: MenuBarIndexer = MenuBarIndexer(),
         repository: ShortcutRepository,
         notifications: NotificationService,
         profileStore: ProfileStore? = nil) {
        self.indexer = indexer
        self.repository = repository
        self.notifications = notifications
        self.profileStore = profileStore
    }

    /// Indexes an application's menu bar and persists any discovered shortcuts.
    func index(_ application: NSRunningApplication) {
        guard let pid = application.processIdentifier as pid_t? else { return }
        let appName = application.localizedName ?? ""
        guard !appName.isEmpty else { return }
        let bundleID = application.bundleIdentifier ?? ""

        let elements = indexer.indexMenuBar(processIdentifier: pid, appName: appName)
        guard !elements.isEmpty else { return }

        do {
            let appID = try repository.upsertApplication(appName: appName, bundleIdentifier: bundleID)
            try repository.upsertMenuBarItems(elements, applicationID: appID)
        } catch {
            NSLog("hotkeyADAM: failed to index \(appName): \(error)")
        }
    }

    /// Handles a click at the given point in the given (frontmost) app:
    /// resolves the element under the cursor and, if a non-disabled shortcut is
    /// known (menu-bar index primary, imported profile opt-in), posts a hint.
    func handleClick(at point: CGPoint, application: NSRunningApplication) {
        guard let pid = application.processIdentifier as pid_t? else { return }
        let appName = application.localizedName ?? ""
        let bundleIdentifier = application.bundleIdentifier ?? ""
        guard !appName.isEmpty else { return }

        let appElement = AXUIElementCreateApplication(pid)
        var axElement: AXUIElement?
        let error = AXUIElementCopyElementAtPosition(appElement, Float(point.x), Float(point.y), &axElement)
        guard error == .success, let axElement else { return }

        let element = AXUIElementReader.element(from: axElement, appName: appName)

        let shortcut: String?
        if let indexed = try? repository.shortcutString(for: element, appName: appName), !indexed.isEmpty {
            shortcut = indexed
        } else {
            shortcut = profileStore?.shortcut(for: element,
                                              appName: appName,
                                              bundleIdentifier: bundleIdentifier)
        }

        guard let shortcut, !element.title.isEmpty else { return }

        notifications.showShortcutHint(appName: appName,
                                       elementTitle: element.title,
                                       shortcutString: shortcut)
    }
}
