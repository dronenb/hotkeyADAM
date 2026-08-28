import Foundation

/// Central application model for hotkeyADAM.
///
/// Phase 1 is a runnable skeleton. Indexing, notifications, and profile
/// features are added in later phases.
@MainActor
final class HotkeyAdamAppModel: ObservableObject {
    @Published var isAccessibilityGranted = false

    let accessibilityService = AccessibilityService()

    func checkAccessibility() {
        isAccessibilityGranted = accessibilityService.isTrusted
    }

    func requestAccessibility() {
        accessibilityService.requestTrust()
        checkAccessibility()
    }
}
