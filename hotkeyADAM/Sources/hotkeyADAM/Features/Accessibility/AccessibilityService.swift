import ApplicationServices
import Foundation

/// Thin wrapper around the macOS Accessibility (AX) trust APIs.
///
/// Phase 1 only exposes the trust check and request prompt. UI element
/// indexing and click monitoring arrive in Phase 2.
final class AccessibilityService {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestTrust() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
