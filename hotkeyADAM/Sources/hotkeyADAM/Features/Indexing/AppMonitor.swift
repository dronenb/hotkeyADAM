import AppKit
import Foundation

/// Observes application activation/launch and routes the frontmost app to the
/// indexing pipeline on a background queue.
final class AppMonitor {
    private let onApplicationActive: (NSRunningApplication) -> Void
    private let queue = DispatchQueue(label: "com.bendronen.hotkeyadam.indexer", qos: .utility)

    private let center = NSWorkspace.shared.notificationCenter
    private var observationTokens = [NSObjectProtocol]()

    init(indexingService: IndexingService) {
        weak let service = indexingService
        self.onApplicationActive = { application in
            service?.index(application)
        }
    }

    func start() {
        register(NSWorkspace.didActivateApplicationNotification)
        register(NSWorkspace.didLaunchApplicationNotification)
    }

    func stop() {
        for token in observationTokens {
            center.removeObserver(token)
        }
        observationTokens.removeAll()
    }

    private func register(_ name: NSNotification.Name) {
        let token = center.addObserver(
            forName: name,
            object: nil,
            queue: .main) { [weak self] notification in
                guard let self else { return }
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                else { return }
                self.queue.async {
                    self.onApplicationActive(app)
                }
            }
        observationTokens.append(token)
    }
}
