import AppKit
import Foundation

/// Central application model for hotkeyADAM.
@MainActor
final class HotkeyAdamAppModel: ObservableObject {
    @Published var isAccessibilityGranted = false

    let accessibilityService = AccessibilityService()

    private let indexingService: IndexingService?
    private let appMonitor: AppMonitor?
    private let clickMonitor = ClickMonitor()

    init() {
        let appDatabase = try? AppDatabase()
        let repository = appDatabase.map { ShortcutRepository(appDatabase: $0) }
        let disableService = repository.map { ShortcutDisableService(repository: $0) }
        let notifications = disableService.map { NotificationService(disableService: $0) }

        if let repository, let notifications {
            self.indexingService = IndexingService(repository: repository,
                                                   notifications: notifications)
        } else {
            self.indexingService = nil
        }

        if let indexingService {
            self.appMonitor = AppMonitor(indexingService: indexingService)
        } else {
            self.appMonitor = nil
        }

        notifications?.configure()
        notifications?.requestAuthorization()
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
