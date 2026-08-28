import ApplicationServices
import Foundation

/// Walks an application's menu bar accessibility tree and collects the
/// elements that expose a keyboard shortcut.
final class MenuBarIndexer {

    /// Returns the set of `UIElement` values (with non-nil shortcuts) found in
    /// the menu bar of the given process identifier.
    func indexMenuBar(processIdentifier pid: pid_t, appName: String) -> [UIElement] {
        let appRef = AXUIElementCreateApplication(pid)
        guard let menuBar = childElement(of: appRef, attribute: kAXMenuBarAttribute) else {
            return []
        }
        return indexChildren(of: menuBar, appName: appName)
    }

    private func indexChildren(of element: AXUIElement, appName: String) -> [UIElement] {
        var results = [UIElement]()

        let children = childrenElements(of: element)
        for child in children {
            let uiElement = AXUIElementReader.element(from: child, appName: appName)
            if uiElement.shortcutString != nil {
                results.append(uiElement)
            }
            // Recurse into submenus.
            results.append(contentsOf: indexChildren(of: child, appName: appName))
        }

        return results
    }

    private func childrenElements(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value)
        guard error == .success, let value else { return [] }
        return value as? [AXUIElement] ?? []
    }

    private func childElement(of element: AXUIElement, attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success else { return nil }
        return value.map { $0 as! AXUIElement }
    }
}
