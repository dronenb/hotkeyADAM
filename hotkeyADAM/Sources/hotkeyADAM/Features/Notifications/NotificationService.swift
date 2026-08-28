import Foundation
import UserNotifications

/// Posts local notifications surfaced by shortcut indexing, and wires up the
/// "disable this hint" action so users can opt out per shortcut.
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let disableActionIdentifier = "DISABLE_SHORTCUT_HINT"

    private let center: UNUserNotificationCenter
    private let disableService: ShortcutDisableService

    init(disableService: ShortcutDisableService,
         center: UNUserNotificationCenter = .current()) {
        self.disableService = disableService
        self.center = center
        super.init()
        center.delegate = self
    }

    /// Requests authorization once; safe to call again if previously denied.
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Configures the notification category and its "disable this hint" action.
    func configure() {
        let disable = UNNotificationAction(identifier: Self.disableActionIdentifier,
                                           title: "Disable this hint",
                                           options: [])
        let category = UNNotificationCategory(identifier: "SHORTCUT_HINT",
                                              actions: [disable],
                                              intentIdentifiers: [],
                                              options: [])
        center.setNotificationCategories([category])
    }

    /// Shows a shortcut hint notification for the given element/app.
    func showShortcutHint(appName: String, elementTitle: String, shortcutString: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(appName) — \(shortcutString)"
        content.body = "Click \(elementTitle) to use it, via \(appName)."
        content.sound = .default
        content.categoryIdentifier = "SHORTCUT_HINT"
        content.userInfo = [
            "appName": appName,
            "elementTitle": elementTitle,
            "shortcutString": shortcutString,
        ]

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        center.add(request) { _ in }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == Self.disableActionIdentifier {
            let info = response.notification.request.content.userInfo
            if let appName = info["appName"] as? String,
               let elementTitle = info["elementTitle"] as? String,
               let shortcutString = info["shortcutString"] as? String {
                disableService.disable(appName: appName,
                                       elementTitle: elementTitle,
                                       shortcutString: shortcutString)
            }
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner])
    }
}
