import ApplicationServices
import Foundation

/// Reads accessibility (AX) attributes from an `AXUIElement` and converts
/// them into the value-type `UIElement` model used by hotkeyADAM.
enum AXUIElementReader {
    /// Reads the attributes for a given AX element into a `UIElement` value.
    static func element(from ref: AXUIElement, appName: String) -> UIElement {
        UIElement(
            role: value(for: ref, attribute: kAXRoleAttribute) ?? "",
            roleDescription: value(for: ref, attribute: kAXRoleDescriptionAttribute) ?? "",
            subrole: value(for: ref, attribute: kAXSubroleAttribute) ?? "",
            title: value(for: ref, attribute: kAXTitleAttribute) ?? "",
            help: value(for: ref, attribute: kAXHelpAttribute) ?? "",
            elementDescription: value(for: ref, attribute: kAXDescriptionAttribute) ?? "",
            parentTitle: value(for: ref, attribute: kAXTitleAttribute, parentOf: ref) ?? "",
            value: value(for: ref, attribute: kAXValueAttribute) ?? "",
            cocoaIdentifier: value(for: ref, attribute: kAXIdentifierAttribute) ?? "",
            shortcutString: shortcutString(for: ref, appName: appName)
        )
    }

    /// Builds a human-readable shortcut string (e.g. "Command Shift P") from a
    /// menu item's cmd-char and cmd-modifiers attributes.
    static func shortcutString(for ref: AXUIElement, appName: String) -> String? {
        let char = value(for: ref, attribute: kAXMenuItemCmdCharAttribute) ?? ""
        guard !char.isEmpty else { return nil }

        var modifiers = [String]()
        if let modValue = rawValue(for: ref, attribute: kAXMenuItemCmdModifiersAttribute),
           let mods = modValue as? NSNumber {
            let flags = mods.uintValue
            if flags & UInt(cmdBit) != 0 { modifiers.append("Command") }
            if flags & UInt(shiftBit) != 0 { modifiers.append("Shift") }
            if flags & UInt(optionBit) != 0 { modifiers.append("Option") }
            if flags & UInt(controlBit) != 0 { modifiers.append("Control") }
        }

        var parts = modifiers
        parts.append(char)
        return parts.joined(separator: " ")
    }

    // MARK: - AX helpers

    // Carbon-style menu modifier bit values (kCmdKey/kShiftKey/kOptionKey/kControlKey).
    private static let cmdBit: UInt = 0x100
    private static let shiftBit: UInt = 0x200
    private static let optionBit: UInt = 0x800
    private static let controlBit: UInt = 0x1000

    private static func rawValue(for ref: AXUIElement, attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(ref, attribute as CFString, &value)
        return error == .success ? value : nil
    }

    private static func value(for ref: AXUIElement, attribute: String) -> String? {
        if let raw = rawValue(for: ref, attribute: attribute) {
            return String.fromCFType(raw)
        }
        return nil
    }

    /// Reads an attribute from the parent of `ref`.
    private static func value(for ref: AXUIElement, attribute: String, parentOf callerRef: AXUIElement) -> String? {
        var parentValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(ref, kAXParentAttribute as CFString, &parentValue)
        guard error == .success, let parentValue else { return nil }
        return value(for: parentValue as! AXUIElement, attribute: attribute)
    }
}

private extension String {
    /// Converts a CFTypeRef (CFString/CFNumber/BOOL) into its string form.
    static func fromCFType(_ value: CFTypeRef) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        case let boolean as Bool:
            return boolean ? "1" : "0"
        default:
            return nil
        }
    }
}
