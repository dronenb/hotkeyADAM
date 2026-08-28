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

    init(indexer: MenuBarIndexer = MenuBarIndexer(),
         repository: ShortcutRepository,
         notifications: NotificationService) {
        self.indexer = indexer
        self.repository = repository
        self.notifications = notifications
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
    /// known, posts a hint notification.
    func handleClick(at point: CGPoint, application: NSRunningApplication) {
        guard let pid = application.processIdentifier as pid_t? else { return }
        let appName = application.localizedName ?? ""
        guard !appName.isEmpty else { return }

        let appElement = AXUIElementCreateApplication(pid)
        var axElement: AXUIElement?
        let error = AXUIElementCopyElementAtPosition(appElement, Float(point.x), Float(point.y), &axElement)
        guard error == .success, let axElement else { return }

        let element = AXUIElementReader.element(from: axElement, appName: appName)

        guard let shortcut = try? repository.shortcutString(for: element, appName: appName) else {
            return
        }
        guard !element.title.isEmpty else { return }

        notifications.showShortcutHint(appName: appName,
                                       elementTitle: element.title,
                                       shortcutString: shortcut)
    }
}
