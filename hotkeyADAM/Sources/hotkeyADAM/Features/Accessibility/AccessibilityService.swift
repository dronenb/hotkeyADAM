import ApplicationServices
import Foundation

/// Thin wrapper around the macOS Accessibility (AX) trust APIs.
final class AccessibilityService {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestTrust() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
