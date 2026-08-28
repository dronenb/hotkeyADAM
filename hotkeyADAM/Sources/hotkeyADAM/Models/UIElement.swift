import Foundation

/// A lightweight representation of a macOS accessibility (AX) element,
/// containing the information hotkeyADAM needs to identify it and to surface
/// an associated keyboard shortcut.
///
/// This is a value-type model; it does not hold an `AXUIElement`.
struct UIElement: Equatable, Sendable {
    let role: String
    let roleDescription: String
    let subrole: String
    let title: String
    let help: String
    let elementDescription: String
    let parentTitle: String
    let value: String
    let cocoaIdentifier: String

    /// The keyboard shortcut string (e.g. "Command Shift P"), if the element
    /// exposes one via the AX menu-item shortcut attributes.
    let shortcutString: String?
}
