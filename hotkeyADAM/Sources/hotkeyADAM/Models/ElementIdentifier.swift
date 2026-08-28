import Foundation

/// Builds the normalized identifier strings used to look up UI elements
/// against per-app profiles.
///
/// This reproduces the legacy hotkeyEVE identifier algorithm so that existing
/// profile data (keyed by e.g. `axbuttonbuttonsafarianewtab`) remains
/// matchable after the rewrite. The primary identifier concatenates
/// `role + roleDescription + appName`; a secondary "cocoa" identifier adds the
/// element's cocoa accessibility identifier when present.
enum ElementIdentifier {
    /// Legacy-compatible primary identifier.
    ///
    /// Mirrors the original `createIdentifier` with the default flags
    /// (role, roleDescription and appName enabled; the rest disabled).
    static func identifier(for element: UIElement, appName: String) -> String {
        let parts = [
            element.role,
            element.roleDescription,
            appName,
        ].filter { !$0.isEmpty }

        return normalize(parts.joined())
    }

    /// Legacy-compatible "cocoa" identifier computed from a cocoa accessibility
    /// identifier attribute when present.
    static func cocoaIdentifier(role: String,
                                roleDescription: String,
                                title: String,
                                elementDescription: String,
                                cocoaAttribute: String) -> String {
        guard !cocoaAttribute.isEmpty else { return "" }
        let parts = [role, roleDescription, title, elementDescription, cocoaAttribute]
        return normalize(parts.joined())
    }

    private static func normalize(_ string: String) -> String {
        string
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }
}
