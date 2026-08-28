import ApplicationServices
import CoreGraphics
import Foundation

/// Listens for global left-mouse-down events and reports the click location so
/// the caller can identify the UI element under the cursor.
final class ClickMonitor {
    var onClick: ((CGPoint) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private let lock = NSLock()

    func start() {
        lock.lock()
        defer { lock.unlock() }
        guard eventTap == nil else { return }

        let mask = CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, _, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<ClickMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handle(event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque())

        guard let tap else { return }
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        lock.lock()
        defer { lock.unlock() }
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handle(_ event: CGEvent) {
        onClick?(event.location)
    }
}
