import AppKit
import Foundation

/// Central application model for hotkeyADAM.
@MainActor
final class HotkeyAdamAppModel: ObservableObject {
    @Published var isAccessibilityGranted = false
    @Published var importedProfiles: [ShortcutProfile] = []

    let accessibilityService = AccessibilityService()
    let profileStore: ProfileStore?
    private let repository: ShortcutRepository?

    private let indexingService: IndexingService?
    private let appMonitor: AppMonitor?
    private let clickMonitor = ClickMonitor()

    init() {
        let appDatabase = try? AppDatabase()
        let repository = appDatabase.map { ShortcutRepository(appDatabase: $0) }
        self.repository = repository
        let disableService = repository.map { ShortcutDisableService(repository: $0) }
        let notifications = disableService.map { NotificationService(disableService: $0) }
        let profileStore = try? ProfileStore()
        self.profileStore = profileStore

        if let repository, let notifications {
            self.indexingService = IndexingService(repository: repository,
                                                   notifications: notifications,
                                                   profileStore: profileStore)
        } else {
            self.indexingService = nil
        }

        if let indexingService {
            self.appMonitor = AppMonitor(indexingService: indexingService)
        } else {
            self.appMonitor = nil
        }

        importedProfiles = profileStore?.profiles ?? []
        notifications?.configure()
        notifications?.requestAuthorization()
    }

    // MARK: - Profiles

    func importProfile(from url: URL) throws {
        guard let profileStore else { throw ProfileStoreError.unavailable }
        try profileStore.importProfile(from: url)
        refreshProfiles()
    }

    func removeProfile(bundleIdentifier: String) {
        profileStore?.removeProfile(bundleIdentifier: bundleIdentifier)
        refreshProfiles()
    }

    private func refreshProfiles() {
        importedProfiles = profileStore?.profiles ?? []
    }

    /// Merged view of indexed shortcuts + imported profile entries, grouped by
    /// app, for display in the shortcuts browser.
    func mergedShortcuts() -> [ShortcutGroup] {
        var groups: [String: [ShortcutRow]] = [:]

        if let indexed = try? repository?.allIndexedShortcuts() {
            for item in indexed {
                groups[item.appName, default: []].append(
                    ShortcutRow(title: item.itemTitle, shortcut: item.shortcut, source: .indexed))
            }
        }

        for profile in importedProfiles {
            let appName = profile.bundleIdentifier
            for entry in profile.entries {
                groups[appName, default: []].append(
                    ShortcutRow(title: entry.title.isEmpty ? entry.uiElementIdentifier : entry.title,
                                shortcut: entry.shortcut,
                                source: .profile))
            }
        }

        return groups
            .map { ShortcutGroup(appName: $0.key, shortcuts: $0.value) }
            .sorted { $0.appName < $1.appName }
    }


    func checkAccessibility() {
        let trusted = accessibilityService.isTrusted
        isAccessibilityGranted = trusted
        if trusted {
            startServices()
        } else {
            stopServices()
        }
    }

    func requestAccessibility() {
        accessibilityService.requestTrust()
        checkAccessibility()
    }

    // MARK: - Services

    private func startServices() {
        guard let indexingService else { return }

        appMonitor?.start()

        clickMonitor.onClick = { [weak indexingService] point in
            guard let indexingService,
                  let app = NSWorkspace.shared.frontmostApplication else { return }
            indexingService.handleClick(at: point, application: app)
        }
        clickMonitor.start()
    }

    private func stopServices() {
        appMonitor?.stop()
        clickMonitor.stop()
        clickMonitor.onClick = nil
    }
}
